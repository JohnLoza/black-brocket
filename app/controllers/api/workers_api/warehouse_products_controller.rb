class Api::WorkersApi::WarehouseProductsController < ApplicationController
  @@category = "ORDERS"
  
  def index
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    current_user = SiteWorker.find_by(authentication_token: params[:authentication_token])
    if @current_user.blank?
      api_authentication_failed
      return
    end

    authorization_result = @current_user.is_authorized?(@@category, "CAPTURE_BATCHES")
    if !authorization_result.any?
      render :status => 200,
             :json => { :success => false, :info => "NO_ENOUGH_PERMISSIONS" }
    end

    warehouse_products = @current_user.Warehouse.Products.joins(:Product).where(:describes_total_stock => true, products: {deleted: false}).includes(:Product).order("products.name asc").paginate(page: params[:page], per_page: 20)
    data = Array.new
    warehouse_products.each do |w_p|
      data << {hash_id: w_p.Product.hash_id, name: w_p.Product.name, existence: w_p.existence, min_stock: w_p.min_stock}
    end

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }
  end
end
