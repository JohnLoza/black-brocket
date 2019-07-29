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
  end
  
  def local
    @states = State.all.order_by_name
    @hash_id = params[:id] || Utils.new_alphanumeric_token
    @local = Hash.new
    
    if params[:id]
      @local = Local.all[params[:id]]
      render_404 unless @local
    end
  end

  def set_local
    render_404 and return unless params[:cities_ids]
    local = {location: params[:location], shipping_cost: params[:shipping_cost]}
    cities = Hash.new

    params[:cities_ids].each_with_index do |city_id, index|
      cities[city_id] = params[:cities_names][index]
    end
    local[:cities] = cities

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

end
