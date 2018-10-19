class Api::WorkersApi::WarehouseProductsController < ApiController
  before_action do
    authenticate_user!(:site_worker)
  end

  def index
    warehouse_products = @current_user.Warehouse.Products.joins(:Product).where(:describes_total_stock => true, products: {deleted_at: nil}).includes(:Product).order("products.name asc").paginate(page: params[:page], per_page: 20)
    data = Array.new
    warehouse_products.each do |w_p|
      data << {hash_id: w_p.Product.hash_id, name: w_p.Product.name, existence: w_p.existence, min_stock: w_p.min_stock}
    end

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }
  end

  def existence
    unless params[:batch]
      render :status => 200,
             :json => { :success => false, :info => "BATCH_MUST_BE_PRESENT" }
      return
    end

    wp = @current_user.Warehouse.Products.where(batch: params[:batch]).take
    unless wp
      render :status => 200,
             :json => { :success => false, :info => "WAREHOUSE_PRODUCT_NOT_FOUND" }
      return
    end

    data = { product_id: wp.product_id, batch: wp.batch, existence: wp.existence }

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }
  end
end
