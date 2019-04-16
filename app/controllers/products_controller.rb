class ProductsController < ApplicationController

  def index
    if logged_in? and session[:user_type] == 'c'
      # when the user logged in #
      @visit = @current_user.DistributorVisits.where(client_recognizes_visit: nil).take
      @warehouse = @current_user.City.State.Warehouse

      if @warehouse.nil?
        flash[:warning] = "Lo sentimos pero no distribuimos nuestros productos en tu zona ¡aún!."
        redirect_to root_path and return
      end

      @products = @warehouse.Products.joins(:Product).active.visible
        .describes_total_stock.by_category(params[:category])
        .search(key_words: params[:search], fields: ['products.name'])
        .paginate(page: params[:page], per_page: 20).includes(:Product)

      @product_prices = @current_user.ProductPrices
      @photos = ProdPhoto.where("product_id in (?) and is_principal=true", @products.map{|p| p.product_id})
    else
      @products = Product.active.visible.by_category(params[:category])
        .search(key_words: params[:search], fields: [:name])
        .paginate(page: params[:page], per_page: 20)
      @photos = ProdPhoto.where("product_id in (?) and is_principal=true", @products.map{|p| p.id}) if @products
    end # if logged_in? and session[:user_type] == 'c' #
  end

  def show
    if logged_in? and session[:user_type] == 'c'
      @w_product = WarehouseProduct.find_by!(hash_id: params[:id])

      @warehouse = @w_product.Warehouse
      @product = @w_product.Product
      @product_price = @current_user.ProductPrices.where(product_id: @product.id).take
    else
      @product = Product.find_by!(hash_id: params[:id])
    end

    if @product
      @photos = @product.Photos
      @questions = ProdQuestion.where(product_id: @product.id).order(created_at: :DESC).limit(10).includes(:Answer)
    else
      redirect_to products_path
    end
  end

  def ask
    product = Product.find_by!(hash_id: params[:id])
    @question = ProdQuestion.new(product_id: product.id, client_id: current_user.id,
                hash_id: random_hash_id(12).upcase,
                description: params[:prod_question][:description])
    @saved = @question.save ? true : false

    respond_to do |format|
      format.js { render :ask, :layout => false }
    end
  end

end
