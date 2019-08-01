class Api::WorkersApi::OrdersController < ApiController
  before_action do
    authenticate_user!(SiteWorker)
  end

  def count
    orders_count = Order.where(state: "PAYMENT_ACCEPTED", warehouse_id: @current_user.warehouse_id).size

    render status: 200, json: {success: true, info: "DATA_RETURNED", data: orders_count}
  end

  def index
    state = params[:state].present? ? params[:state] : ["PAYMENT_ACCEPTED","LOCAL"]

    orders = Order.where(state: state, warehouse_id: @current_user.warehouse_id)
      .order(created_at: :asc).paginate(page: params[:page], per_page: 25).includes(:Client, :Distributor)

    data = Array.new
    orders.each do |order|
      client = order.Client
      distributor = order.Distributor
      hash = {folio: order.hash_id, date: order.created_at, client: order.client_id,
        client_avatar: client.avatar_url, client_username: client.name, state: order.state,
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

    render status: 200, json: {success: true, info: "DATA_RETURNED", data: data}
  end

  def save_details
    order = Order.find_by!(hash_id: params[:id])
    unless ["PAYMENT_ACCEPTED", "LOCAL"].include? order.state 
      render status: 200, json: {success: false, info: "ORDER_NOT_ELIGIBLE"} and return
    end

    ActiveRecord::Base.transaction do
      order_details = OrderDetail.required_products_hash(order.id)

      params[:product_id].each_with_index do |product_id, indx|
        detail = OrderProductShipmentDetail.create!(order_id: order.id, batch: params[:batch][indx],
          product_id: product_id, quantity: params[:quantity][indx], warehouse_id: order.warehouse_id)
        detail.warehouse_detail.withdraw(detail.quantity)
        order_details[product_id][:quantity_captured] += detail.quantity
      end
      verify_details_captured(order_details)

      order.state = order.state == "LOCAL" ? "PICKED_UP" : "BATCHES_CAPTURED"
      order.save!
      OrderAction.create!(order_id: order.id, worker_id: @current_user.id, description: "Capturó lotes y cantidades")
    end # Transaction #

    render status: 200, json: {success: true, info: "BATCHES_CAPTURED"}
  rescue ActiveRecord::RecordInvalid => e
    render status: 200, json: {success: false, info: "NOT_SAVED", error: e.record.errors.full_messages[0]}
  rescue ActiveRecord::RangeError
    error = "Las cantidades solicitadas por el cliente y las capturadas no coinciden"
    render status: 200, json: {success: false, info: "NOT_SAVED", error: error}
  end # def save_details #

  private
    def verify_details_captured(details)
      details.keys.each do |product_id|
        if details[product_id][:products_required_by_the_user] != details[product_id][:quantity_captured]
          raise ActiveRecord::RangeError, "Cantidades solicitadas y capturadas no coinciden"
        end
      end
    end
end
