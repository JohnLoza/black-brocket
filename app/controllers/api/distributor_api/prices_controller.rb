class Api::DistributorApi::PricesController < ApplicationController
  def index
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    current_user = Distributor.find_by(authentication_token: params[:authentication_token])
    if current_user.blank?
      api_authentication_failed
      return
    end

    client = Client.find_by(hash_id: params[:id])
    if client.blank?
      render :status => 200,
             :json => { :success => false, :info => "CLIENT_NOT_FOUND" }
      return
    end

    product_prices = client.ProductPrices
    products = Product.where(deleted: false).order(name: :asc)
    current_user.updateRevision(client)

    data = Array.new
    products.each do |product|
      hash = {id: product.id, name: product.name, lowest_price: product.lowest_price,
              recommended_price: product.recommended_price, max_price: product.price, current_price: 0}
      if product_prices.any?
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
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    current_user = Distributor.find_by(authentication_token: params[:authentication_token])
    if current_user.blank?
      api_authentication_failed
      return
    end

    client = Client.find_by(hash_id: params[:id])
    if client.blank?
      render :status => 200,
             :json => { :success => false, :info => "CLIENT_NOT_FOUND" }
      return
    end

    ActiveRecord::Base.transaction do
      client.ProductPrices.delete_all
      params[:product].each do |param|
        ClientProduct.create(client_id: client.id, product_id: param[0], client_price: param[1])
      end

      client.update_attributes(has_custom_prices: true, is_new: false)
    end

    render :status => 200,
           :json => { :success => true, :info => "SAVED" }
  end
end
