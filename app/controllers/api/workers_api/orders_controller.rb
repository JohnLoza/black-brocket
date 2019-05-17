class Api::WorkersApi::OrdersController < ApiController
  before_action do
    authenticate_user!(:site_worker)
  end

  def count
    orders_count = Order.where(state: "PAYMENT_ACCEPTED", warehouse_id: @current_user.warehouse_id).size

    render status: 200, json: {success: true, info: "DATA_RETURNED", data: orders_count}
  end

  def index
    orders = Order.where(state: "PAYMENT_ACCEPTED", warehouse_id: @current_user.warehouse_id)
              .order(created_at: :asc).paginate(page: params[:page], per_page: 25).includes(:Client, :Distributor)

    data = Array.new
    orders.each do |order|
      client = order.Client
      distributor = order.Distributor
      hash = {folio: order.hash_id, date: order.created_at, client: order.client_id,
        client_avatar: client.avatar_url, client_username: client.name,
        distributor: order.distributor_id, distributor_avatar: nil, distributor_username: nil}

      if distributor
        hash[:distributor_avatar] = distributor.avatar_url
        hash[:distributor_username] = distributor.username
      end
      data << hash
    end

    render status: 200, json: {success: true, info: "DATA_RETURNED", data: data}
  end

  def show
    order = Order.find_by!(hash_id: params[:id])

    warehouse = order.Warehouse
    details = order.Details.includes(:Product)

    data = Hash.new
    data[:shipping_cost] = order.shipping_cost

    city = warehouse.City
    warehouse_data = {address: warehouse.address, city: city.name,
      state: city.State.name, lada: city.lada, telephone: warehouse.telephone }

    data[:warehouse_data] = warehouse_data

    details_data = Array.new
    details.each do |detail|
      product = detail.Product
      details_data << {id: product.id, product: product.name, presentation: product.presentation,
        product_unit_price: detail.price, quantity: detail.quantity, iva: detail.iva, ieps: detail.ieps,
        total_iva: detail.total_iva, total_ieps: detail.total_ieps}
    end
    data[:order_details] = details_data

    render status: 200, json: {success: true, info: "DATA_RETURNED", data: data}
  end

  def supplied
    orders = Order.where(state: "BATCHES_CAPTURED", warehouse_id: @current_user.warehouse_id).order(created_at: :asc).paginate(page: params[:page], per_page: 25)
    data = Array.new
    orders.each do |order|
      data << {folio: order.hash_id, date: order.created_at, client: order.client_id, distributor: order.distributor_id}
    end

    render status: 200,
           json: {success: true, info: "DATA_RETURNED", data: data}
  end

  def save_details
    used_render_already = false
    order = Order.find_by!(hash_id: params[:id])
    render status: 200, json: {success: false, info: "ORDER_NOT_ELIGIBLE"} and return unless order.state == "PAYMENT_ACCEPTED"
    
    ActiveRecord::Base.transaction do
      indx = 0
      while indx < params[:product_id].size do
        detail = OrderProductShipmentDetail.create(order_id: order.id, batch: params[:batch][indx],
          product_id: params[:product_id][indx], quantity: params[:quantity][indx], warehouse_id: order.warehouse_id)
        # Rollback if there are any errors
        if detail.errors.any?
          render status: 200, json: {success: false, info: detail.errors.full_messages[0]}
          used_render_already = true and raise ActiveRecord::Rollback
        end
        # Withdraw the quantity used for the shipment detail
        detail.warehouse_detail.withdraw(detail.quantity) and indx += 1
      end

      shipment_details = OrderProductShipmentDetail.select("product_id, sum(quantity) as t_quantity")
        .where(order_id: order.id).group(:product_id)
      order_details = OrderDetail.select(:product_id, :quantity).where(order_id: order.id)
      # Review quantities to see that are the same that the client wanted
      validation = CustomValidation.validateOrderShipment(order_details, shipment_details)
      unless validation[:success]
        render status: 200, json: {success: false, info: validation[:error_message]}
        used_render_already = true and raise ActiveRecord::Rollback
      end

      order.update_attribute(:state, "BATCHES_CAPTURED")
      OrderAction.create(order_id: order.id, worker_id: @current_user.id, description: "Capturó lotes y cantidades")
    end # Transaction #
    return if used_render_already
    render status: 200, json: {success: true, info: "BATCHES_CAPTURED"}
  end # def save_details #
end
