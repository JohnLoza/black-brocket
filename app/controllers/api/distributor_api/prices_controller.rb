class Api::DistributorApi::PricesController < ApiController
  before_action do
    authenticate_user!(:distributor)
  end

  def index
    client = Client.find_by!(hash_id: params[:id])

    product_prices = client.ProductPrices
    products = Product.where(deleted_at: nil).order(name: :asc)
    @current_user.updateRevision(client)

    data = Array.new
    products.each do |product|
      hash = {id: product.id, name: product.name, lowest_price: product.lowest_price,
              recommended_price: product.recommended_price, max_price: product.price, current_price: 0}
      if product_prices
        product_prices.each do |price|
          if price.product_id == product.id
            hash[:current_price] = price.client_price
            break
          end
        end
      end # if product_prices.any? #

      data << hash
    end # products each do #

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }
  end

  def update
    client = Client.find_by!(hash_id: params[:id])

    ActiveRecord::Base.transaction do
      client.ProductPrices.delete_all
      params[:product].each do |product_id|
        ClientProduct.create(client_id: client.id, product_id: product_id, client_price: params[:product][product_id])
      end

      client.update_attributes(has_custom_prices: true, is_new: false)
    end

    render :status => 200,
           :json => { :success => true, :info => "SAVED" }
  end
end
