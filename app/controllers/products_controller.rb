class ProductsController < ApplicationController

  def index
    @warehouses = Warehouse.all
    if logged_in? and session[:user_type] == "c"
      # when the user logged in #
      @visit = @current_user.DistributorVisits.where(client_recognizes_visit: nil).take
      @warehouse = @current_user.City.State.Warehouse

      unless @warehouse
        flash[:warning] = "Lo sentimos pero no distribuimos nuestros productos en tu zona ¡aún!."
        redirect_to root_path and return
      end

      @products = @warehouse.Products.joins(:Product).active.visible
        .describes_total_stock.by_category(params[:category])
        .search(key_words: params[:search], fields: ["products.name"])
        .paginate(page: params[:page], per_page: 20).includes(:Product)

      @prices = @current_user.ProductPrices
      @photos = ProdPhoto.where("product_id in (?) and is_principal=true", @products.map{|p| p.product_id})
    else
      @products = Product.active.visible.by_category(params[:category])
        .search(key_words: params[:search], fields: [:name])
        .paginate(page: params[:page], per_page: 20)
      @photos = ProdPhoto.where("product_id in (?) and is_principal=true", @products.map{|p| p.id}) if @products
    end # if logged_in? and session[:user_type] == "c" #
  end

  def show
    if logged_in? and session[:user_type] == "c"
      @warehouse_product = WarehouseProduct.find_by!(hash_id: params[:id])

      @warehouse = @warehouse_product.Warehouse
      @product = @warehouse_product.Product
      @product_price = @current_user.ProductPrices.where(product_id: @product.id).take
    else
      @product = Product.find_by!(hash_id: params[:id])
    end

    redirect_to products_path and return unless @product
    @photos = @product.Photos
    @questions = ProdQuestion.where(product_id: @product.id).order(created_at: :DESC).limit(10).includes(:Answer)
  end

  def ask
    product = Product.find_by!(hash_id: params[:id])
    @question = ProdQuestion.create(product_id: product.id, client_id: current_user.id,
      hash_id: Utils.new_alphanumeric_token(9).upcase, description: params[:prod_question][:description])

    respond_to do |format|
      format.js { render :ask, layout: false }
    end
  end

end
