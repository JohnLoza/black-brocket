class ProductsController < ApplicationController

  def index
    if logged_in? and session[:user_type] == 'c'
      # when the user logged in #
      @visit = @current_user.DistributorVisits.where(client_recognizes_visit: nil).take
      @warehouse = @current_user.City.State.Warehouse

      if @warehouse.nil?
        flash[:warning] = "Lo sentimos pero no distribuimos nuestros productos en tu zona ¡aún!."
        redirect_to root_path
        return
      end

      if params[:category]
        if params[:category] == "hot" or params[:category] == "cold" or params[:category] == "frappe"
          @products = @warehouse.Products.joins(:Product).where(products:{show:true, deleted: false, "#{params[:category]}" => true}, describes_total_stock: true).paginate(:page => params[:page], :per_page => 18).includes(:Product)
        else
          flash[:info] = "Categoría no encontrada."
          redirect_to products_path
          return
        end
      elsif !params[:search].blank?
        @products = @warehouse.Products.joins(:Product).where(products:{show:true, deleted: false}, describes_total_stock: true).where("products.name like '%#{params[:search]}%'").paginate(:page => params[:page], :per_page => 18).includes(:Product)
      else
        @products = @warehouse.Products.joins(:Product).where(products:{show:true, deleted: false}, describes_total_stock: true).paginate(:page => params[:page], :per_page => 18).includes(:Product)
      end

      @product_prices = @current_user.ProductPrices

      @photos = ProdPhoto.where("product_id in (?) and is_principal=true", @products.map{|p| p.product_id})

    else
      # when the user hasn't logged in #
      if params[:category]
        if params[:category] == "hot" or params[:category] == "cold" or params[:category] == "frappe"
          @products = Product.where(show: true, deleted: false, "#{params[:category]}" => true).paginate(:page => params[:page], :per_page => 18)
        else
          flash[:info] = "Categoría no encontrada."
          redirect_to products_path
          return
        end
      elsif !params[:search].blank?
        @products = Product.where(show: true, deleted: false).where("products.name like '%#{params[:search]}%'").paginate(:page => params[:page], :per_page => 18)
      else
        @products = Product.where(show: true, deleted: false).paginate(:page => params[:page], :per_page => 18)
      end
      @photos = ProdPhoto.where("product_id in (?) and is_principal=true", @products.map{|p| p.id}) if @products
    end # if logged_in? and session[:user_type] == 'c' #
  end

  def show
    if logged_in? and session[:user_type] == 'c'
      @w_product = WarehouseProduct.find_by(hash_id: params[:id])

      if @w_product.nil?
        flash[:info] = "No se encontró el producto con clave: #{params[:id]}."
        redirect_to products_path
        return
      end

      @warehouse = @w_product.Warehouse
      @product = @w_product.Product
      @product_price = @current_user.ProductPrices.where(product_id: @product.id).take
    else
      @product = Product.find_by(hash_id: params[:id])
    end

    if @product
      @photos = @product.Photos
      @questions = ProdQuestion.where(product_id: @product.id).order(created_at: :DESC).limit(10).includes(:Answer)
    else
      redirect_to products_path
    end
  end

  def ask
    product = Product.find_by(hash_id: params[:id])
    @question = ProdQuestion.new(product_id: product.id, client_id: @current_user.id,
                hash_id: random_hash_id(12).upcase,
                description: params[:prod_question][:description])

    @saved = false
    if @question.save
      @saved = true
    end

    respond_to do |format|
      format.js { render :ask, :layout => false }
    end
  end

end
