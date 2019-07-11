class Client::EcartsController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_client?

  def show
    if @current_user.street.nil?
      flash[:info] = "Por favor completa tus datos de envío."
      redirect_to edit_client_client_path @current_user and return
    end

    if session[:e_cart]
      @products = WarehouseProduct.where("hash_id in (?)", session[:e_cart].keys).includes(:Product)
      @product_prices = @current_user.ProductPrices.where("product_id in (?)", @products.map(&:product_id))
      @warehouse = @products[0].Warehouse if @products.any?
      # @parcels = @warehouse.Parcels.exclude_local_delivery
      @banks = Bank.all

      @photos = ProdPhoto.where("product_id in (?) and is_principal=true", @products.map{|p| p.product_id})
      @total = 0

      @local_regions = [
        19597, # Guadalajara, jal
        19676, # Zapopan, jal
        19655, # Tlaquepaque, jal
        19658  # Tonalá, jal
      ]
    end
  end

  def add_to_cart
    @product = WarehouseProduct.find_by!(hash_id: params[:id])

    @quantity_is_correct = true if params[:quantity].to_i > 0 and @product.existence >= params[:quantity].to_i

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
      format.js { render :add_to_cart, layout: false }
    end
  end

  def remove_from_cart
    render_404 and return unless session[:e_cart].present?
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
    render_404 and return unless session[:e_cart].present?
    @updated = false
    if session[:e_cart].has_key?(params[:product]) and params[:new_quantity].to_i > 0 and
      params[:new_quantity] != session[:e_cart][params[:product]]

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
      format.js { render :update_quantity, layout: false }
    end
  end

  def sr_parcel_prices
    render_404 and return unless session[:e_cart].present?

    cart_weight = session[:e_cart]["total_weight"];
    @boxes_selected, available_boxes = selectBoxes(cart_weight)
    
    @parcels = Hash.new
    @boxes_selected.keys.each do |key|
      box = available_boxes.select{|box| box["name"] == key }[0] # get the box obj
      jsonArray = fetchSrQuotations(@current_user.cp, box) # get Quotations from Sr Envío
      no_boxes = @boxes_selected[key]

      jsonArray.each do |obj| # build up @parcels json
        key = "#{obj['provider']}_#{obj['service_level_code']}"
        @parcels[key] = obj unless @parcels[key].present?

        if @parcels[key] and @parcels[key]["grand_total"].present?
          @parcels[key]["grand_total"] += obj["total_pricing"].to_f * no_boxes
        else
          @parcels[key]["grand_total"] = obj["total_pricing"].to_f * no_boxes
        end # end if "grand_total"
      end # end jsonArray.each
    end # end boxes_selected.keys.each

    respond_to do |format|
      format.js { render :sr_parcel_prices, layout: false}
    end
  end

  private
    def fetchSrQuotations(zc, box)
      res = `curl \"https://api-demo.srenvio.com/v1/quotations\" \\
        -H \"Authorization: Token token=PhrFxG93iBFSQpDwmTuYGeESANNpJjNTF91l6Hf3AXQt\" \\
        -H \"Content-Type: application/json\" --request POST \\
        --data '{\"zip_from\":\"44100\",\"zip_to\":\"#{zc}\",\"parcel\":{\"weight\":#{box["weight"]},\"height\":#{box["height"]},\"width\":#{box["width"]},\"length\":#{box["length"]}}}'`

      return JSON.parse res
    end

    def selectBoxes(cart_weight)
      boxes = BbConfig.getBoxes
      boxes_selected = Hash.new
      remaining_cart_weight = cart_weight.to_f / 1000
    
      while remaining_cart_weight > 0 # keep adding boxes til there is no product left
        boxes.each do |box|
          use_this_box = false
          if remaining_cart_weight > box["weight"] or # if box is used fully
            (remaining_cart_weight * 100 / box["weight"]).between?(70, 99) # or between 70 to 99 percent

            no_boxes = (remaining_cart_weight / box["weight"]).floor
            no_boxes = 1 if no_boxes = 0 # change no_boxes to 1 when box is almost full
            
            if boxes_selected[box["name"]].present?
              boxes_selected[box["name"]] += no_boxes
            else
              boxes_selected[box["name"]] = no_boxes
            end

            remaining_cart_weight -= no_boxes * box["weight"]
            use_this_box = true
          end # end if
          break if use_this_box
        end # end boxes.each

        # use the smallest box for the last resort
        if remaining_cart_weight > 0 and remaining_cart_weight < boxes.last["weight"]
          if boxes_selected[boxes.last["name"]].present?
            boxes_selected[boxes.last["name"]] += 1
          else
            boxes_selected[boxes.last["name"]] = 1
          end
          remaining_cart_weight -= boxes.last["weight"]
        end # end if 
      end # end while

      return boxes_selected, boxes
    end

end
