class Api::DistributorApi::OrdersController < ApiController
  before_action do
    authenticate_user!(Distributor)
  end

  def index
    if params[:client].blank?
      orders = @current_user.Orders.order(updated_at: :desc).limit(100)
        .paginate(page: params[:page], per_page: 25).includes(:Client, City: :State)
    else
      client = Client.find_by!(hash_id: params[:client])
      if !client.blank?
        orders = Order.where(client_id: client.id).order(updated_at: :desc).limit(100)
          .paginate(page: params[:page], per_page: 25).includes(City: :State)
        @current_user.updateRevision(client)
      else
        render status: 200, json: {success: false, info: "CLIENT_NOT_FOUND"} and return
      end
    end

    data = Array.new
    orders.each do |order|
      data << {hash_id: order.hash_id, client_username: order.Client.username, client_hash_id: order.Client.hash_id,
        date: I18n.l(order.created_at, format: :long), total: order.total, status: I18n.t(order.state), city: order.City.name, state: order.City.State.name }
    end
    home_img = @current_user.home_img.url
    avatar = @current_user.avatar_url

    render status: 200, json: {success: true, info: "DATA_RETURNED", 
      avatar: avatar, home_img: home_img, data: data}
  end

  def show
    order = Order.find_by!(hash_id: params[:id])

    fiscal_data = order.Client.FiscalData
    warehouse = order.Warehouse
    details = order.Details

    data = Hash.new
    data[:shipping_cost] = order.shipping_cost
    data[:cancel_description] = order.cancel_description
    data[:reject_description] = order.reject_description

    city = warehouse.City
    warehouse_data = {address: warehouse.address, city: city.name,
      state: city.State.name, lada: city.lada, telephone: warehouse.telephone }

    data[:warehouse_data] = warehouse_data
    data[:fiscal_data] = fiscal_data
    data[:state_name] = fiscal_data.City.State.name if fiscal_data
    data[:city_name] = fiscal_data.City.name if fiscal_data

    details_data = Array.new
    details.each do |detail|
      product = detail.Product
      details_data << {product: product.name, presentation: product.presentation,
        product_unit_price: detail.price, quantity: detail.quantity, iva: detail.iva, ieps: detail.ieps,
        total_iva: detail.total_iva, total_ieps: detail.total_ieps}
    end
    data[:order_details] = details_data

    render status: 200, json: {success: true, info: "DATA_RETURNED", data: data}
  end
end
