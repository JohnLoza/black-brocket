class Api::WorkersApi::OrdersController < ApiController
  before_action do
    authenticate_user!(:site_worker)
  end

  def count
    orders_count = Order.where(state: "PAYMENT_ACCEPTED", warehouse_id: @current_user.warehouse_id).size

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => orders_count }
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

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }
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

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }
  end

  def supplied
    orders = Order.where(state: "BATCHES_CAPTURED", warehouse_id: @current_user.warehouse_id).order(created_at: :asc).paginate(page: params[:page], per_page: 25)
    data = Array.new
    orders.each do |order|
      data << {folio: order.hash_id, date: order.created_at, client: order.client_id, distributor: order.distributor_id}
    end

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }
  end

  def save_details
    success = false
    @order = Order.find_by!(hash_id: params[:id])

    if @order.state == "PAYMENT_ACCEPTED"
      ActiveRecord::Base.transaction do

        indx = 0
        while indx < params[:product_id].size do
          product_detail =
            WarehouseProduct.where(warehouse_id: @order.warehouse_id,
                                   product_id: params[:product_id][indx],
                                   batch: params[:batch][indx]).take

          # if the product with the given key and batch doesn't exist stop the execution #
          if !product_detail
            puts "--- product not found ---"
            render :status => 200,
                   :json => { :success => false, :info => "PRODUCT_NOT_FOUND", :data => {id: params[:product_id][indx], batch: params[:batch][indx]} }
            raise ActiveRecord::Rollback
          end # if !product_detail #

          # if the current existence of the product is less than the one captured stop the execution #
          if product_detail.existence >= params[:quantity][indx].to_i
            product_detail.update_attribute(:existence,
                          product_detail.existence - params[:quantity][indx].to_i)
          else
            puts "--- no enough existence for delivery ---"
            render :status => 200,
                   :json => { :success => false, :info => "NO_ENOUGH_EXISTENCE", :data => {id: params[:product_id][indx], batch: params[:batch][indx]} }
            raise ActiveRecord::Rollback
          end

          OrderProductShipmentDetail.create(order_id: @order.id,
                          product_id: params[:product_id][indx],
                          quantity: params[:quantity][indx],
                          batch: params[:batch][indx])

          indx += 1
        end # while indx < params[:product_id].size #

        # review quantities to see that are the same that the client wanted
        shipment_details = OrderProductShipmentDetail.select("product_id, sum(quantity) as t_quantity")
                              .where(order_id: @order.id).group(:product_id)
        order_details = OrderDetail.select(:product_id, :quantity).where(order_id: @order.id)

        product_captured = true
        order_details.each do |order_detail|

          # if a product hasn't been captured stop the execution #
          if !product_captured
            puts "--- a product hasn't been captured ---"
            render :status => 200,
                   :json => { :success => false, :info => "PRODUCT_NOT_CAPTURED" }
            raise ActiveRecord::Rollback
          end

          product_captured = false
          shipment_quantity = 0

          # iterate through the shipment details to verify the product quantities are the ones the client wanted #
          shipment_details.each do |shipment_detail|
            if order_detail.product_id == shipment_detail.product_id
              shipment_quantity += shipment_detail.t_quantity
            end
          end

          if order_detail.quantity != shipment_quantity
            puts "--- quantities don't match ---"
            render :status => 200,
                   :json => { :success => false, :info => "QUANTITIES_DONT_MATCH" }
            raise ActiveRecord::Rollback
          else
            product_captured = true
          end
        end

        @order.update_attribute(:state, "BATCHES_CAPTURED")
        puts "--- every thing went OK while validating quantities ---"
        success = true
      end # Transaction #

    end # if @order #

    if success
      OrderAction.create(order_id: @order.id, worker_id: @current_user.id, description: "Capturó lotes y cantidades")
      render :status => 200,
             :json => { :success => true, :info => "BATCHES_CAPTURED" }
      return
    end
  end
end
