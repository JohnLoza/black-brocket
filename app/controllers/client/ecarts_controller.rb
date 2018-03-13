class Client::EcartsController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_client?

  def show
    if session[:e_cart]
      @products = WarehouseProduct.where("hash_id in (?)", session[:e_cart].keys).includes(:Product)
      @product_prices = @current_user.ProductPrices.where("product_id in (?)", @products.map(&:product_id))
      @warehouse = @products[0].Warehouse if @products.any?
      @banks = Bank.all

      @photos = ProdPhoto.where("product_id in (?) and is_principal=true", @products.map{|p| p.product_id})
      @total = 0
    end
  end

  def add_to_cart
    @product = WarehouseProduct.find_by!(hash_id: params[:id])

    @quantity_is_correct = true if params[:quantity].to_i > 0 and
                                   @product.existence >= params[:quantity].to_i

    if @quantity_is_correct
      session[:e_cart] = {} if !session[:e_cart]
      session[:e_cart][params[:id]] = params[:quantity]
    end

    respond_to do |format|
      format.js { render :add_to_cart, :layout => false }
    end
  end

  def remove_from_cart
    # remove the selected item from the cart #
    if session[:e_cart].has_key?(params[:product])
      session[:e_cart].delete(params[:product])
      session.delete(:e_cart) if session[:e_cart].empty?
    end

    flash[:success] = "Producto eliminado del carrito!"
    redirect_to client_ecart_path
  end

  def update_quantity
    @updated = false
    if session[:e_cart].has_key?(params[:product]) and
            params[:new_quantity] != session[:e_cart][params[:product]] and
            params[:new_quantity].to_i > 0

      @prev_quantity = session[:e_cart][params[:product]]

      if params[:new_quantity].to_i <= params[:current_existence].to_i
        session[:e_cart][params[:product]] = params[:new_quantity]
      else
        session[:e_cart][params[:product]] = params[:current_existence]
        params[:new_quantity] = params[:current_existence]
        @reached_current_existence = true
      end

      @updated = true
    end

    respond_to do |format|
      format.js { render :update_quantity, :layout => false }
    end
  end
end
