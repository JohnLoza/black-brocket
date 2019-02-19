class Client::EcartsController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_client?

  def show
    if session[:e_cart]
      @products = WarehouseProduct.where("hash_id in (?)", session[:e_cart].keys).includes(:Product)
      @product_prices = @current_user.ProductPrices.where("product_id in (?)", @products.map(&:product_id))
      @warehouse = @products[0].Warehouse if @products.any?
      @parcels = @warehouse.Parcels
      @banks = Bank.all

      @photos = ProdPhoto.where("product_id in (?) and is_principal=true", @products.map{|p| p.product_id})
      @total = 0
    end
  end

  def add_to_cart
    @product = WarehouseProduct.find_by!(hash_id: params[:id])

    @quantity_is_correct = true if params[:quantity].to_i > 0 and
                                   @product.existence >= params[:quantity].to_i

    return unless @quantity_is_correct
    unless session[:e_cart]
      session[:e_cart] = Hash.new
      session[:e_cart]["total_weight"] = 0
    end

    # calculate the added_weight to the cart
    if session[:e_cart][@product.hash_id]
      new_quantity = params[:quantity].to_i - session[:e_cart][@product.hash_id].to_i
      added_weight = @product.Product.total_weight * new_quantity
    else
      added_weight = @product.Product.total_weight * params[:quantity].to_i
    end

    # add product and quantity to session
    session[:e_cart][@product.hash_id] = params[:quantity]
    session[:e_cart]["total_weight"] += added_weight

    respond_to do |format|
      format.js { render :add_to_cart, :layout => false }
    end
  end

  def remove_from_cart
    # remove the selected item from the cart #
    if session[:e_cart].has_key?(params[:product])
      product_weight = WarehouseProduct.find_by!(hash_id: params[:product]).Product.total_weight
      session[:e_cart]["total_weight"] -= product_weight * session[:e_cart][params[:product]].to_i

      session[:e_cart].delete(params[:product])
      session.delete(:e_cart) if session[:e_cart].size == 1
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

      # update the total_weight accordingly
      product_weight = WarehouseProduct.find_by!(hash_id: params[:product]).Product.total_weight
      quantity_diff = session[:e_cart][params[:product]].to_i - @prev_quantity.to_i
      added_weight = product_weight * quantity_diff
      session[:e_cart]["total_weight"] += added_weight

      @updated = true
    end

    respond_to do |format|
      format.js { render :update_quantity, :layout => false }
    end
  end

  def parcel_prices
    @parcel = Parcel.find(params[:id])
    @prices = @parcel.Prices.order(max_weight: :asc)

    respond_to do |format|
      format.js { render :parcel_prices, :layout => false}
    end
  end
end
