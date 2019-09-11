class Admin::BbConfigurationController < AdminController
  def index
  end

  def boxes
    begin
      @boxes = Box.all
    rescue Errno::ENOENT # when file doesnt exist
      @boxes = Hash.new
    end # begin end
  end

  def set_boxes
    json_array = Array.new

    # build json array
    params[:weight].each_with_index do |value, indx|
      json_array << {
        name: params[:name][indx],
        weight: params[:weight][indx].to_f,
        box_weight: params[:box_weight][indx].to_f,
        height: params[:height][indx].to_f,
        width: params[:width][indx].to_f, 
        length: params[:length][indx].to_f
      }
    end

    Box.setBoxes(json_array)
    flash[:success] = "Cajas guardadas"
    redirect_to admin_boxes_configuration_path()
  end

  def locals
    begin
      @locals = Local.all
    rescue Errno::ENOENT # when file doesnt exist
      @locals = Hash.new
    end # begin end

    @locals.keys.any? or return

    cities_ids = Array.new
    @locals.values.each{|local| local["cities"].each{|city| cities_ids << city }}
    @cities = City.where(id: cities_ids)
  end
  
  def local
    @states = State.all.order_by_name
    @hash_id = params[:id] || Utils.new_alphanumeric_token
    @local = Hash.new
    
    if params[:id]
      @local = Local.all[params[:id]]
      render_404 and return unless @local
      @cities = City.where(id: @local["cities"])
    end
  end

  def set_local
    render_404 and return unless params[:id] and params[:cities_ids]

    local = {location: params[:location], shipping_cost: params[:shipping_cost]}
    local[:cities] = params[:cities_ids].map {|city_id| city_id.to_i}
      
    begin
      locals = Local.all
    rescue Errno::ENOENT # when file doesnt exist
      locals = Hash.new
    end # begin end

    locals[params[:id]] = local
    Local.setLocals(locals)

    flash[:success] = "Local guardado"
    redirect_to admin_locals_configuration_path()
  end

  def destroy_local
    locals = Local.all
    locals.delete(params[:id])
    Local.setLocals(locals)

    flash[:info] = "Local eliminado"
    redirect_to admin_locals_configuration_path()
  end

  def offers
    @products = Product.active
    @offers = WebOffer.getSpecialOffers
  end

  def set_offers
    json_array = Array.new

    params[:product_id].each_with_index do |value, indx|
      json_array << {
        product_id: params[:product_id][indx].to_i,
        discount: params[:discount][indx].to_f,
        start_at: params[:start_at][indx],
        expire_at: params[:expire_at][indx]
      }
    end

    WebOffer.setSpecialOffers(json_array)
    flash[:success] = "Ofertas guardadas"
    redirect_to admin_offers_configuration_path()
  end

  def destroy_offers
    WebOffer.setSpecialOffers(nil)
    flash[:success] = "Ofertas eliminadas"
    redirect_to admin_offers_configuration_path()
  end

end
