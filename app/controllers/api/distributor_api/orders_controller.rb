class Api::DistributorApi::OrdersController < ApplicationController
  def index
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    @current_user = Distributor.find_by(authentication_token: params[:authentication_token])
    if @current_user.blank?
      api_authentication_failed
      return
    end

    if params[:client].blank?
      orders = @current_user.Orders.order(updated_at: :desc).limit(100).paginate(:page => params[:page], :per_page => 25).includes(City: :State).includes(:Client, City: :State)
    else

      client = Client.find_by(hash_id: params[:client])
      if !client.blank?
        orders = Order.where(client_id: client.id).order(updated_at: :desc).limit(100).paginate(:page => params[:page], :per_page => 25).includes(City: :State)
        @current_user.updateRevision(client)
      else
        render :status => 200,
               :json => { :success => false, :info => "CLIENT_NOT_FOUND" }
        return
      end

    end

    data = Array.new
    orders.each do |order|
      data << {hash_id: order.hash_id, client_username: order.Client.username, client_hash_id: order.Client.hash_id,
        date: l(order.created_at, format: :long), total: order.total, status: t(order.state), city: order.City.name, state: order.City.State.name }
    end

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }
  end

  def show
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    @current_user = Distributor.find_by(authentication_token: params[:authentication_token])
    if @current_user.blank?
      api_authentication_failed
      return
    end

    order = @current_user.Orders.where(hash_id: params[:id]).take
    if order.blank?
      render :status => 200,
             :json => { :success => false, :info => "ORDER_NOT_FOUND" }
      return
    end

    fiscal_data = order.Client.FiscalData
    warehouse = order.Warehouse
    details = order.Details

    data = Hash.new
    data[:shipping_cost] = order.shipping_cost

    city = warehouse.City
    warehouse_data = {address: warehouse.address, city: city.name,
      state: city.State.name, lada: city.lada, telephone: warehouse.telephone }

    data[:warehouse_data] = warehouse_data
    data[:fiscal_data] = fiscal_data
    data[:state_name] = fiscal_data.City.State.name
    data[:city_name] = fiscal_data.City.name

    details_data = Array.new
    details.each do |detail|
      product = detail.Product
      details_data << {product: product.name, presentation: product.presentation,
        product_unit_price: detail.price, quantity: detail.quantity, iva: detail.iva, ieps: detail.ieps,
        total_iva: detail.total_iva, total_ieps: detail.total_ieps}
    end
    data[:order_details] = details_data

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }
  end
end
