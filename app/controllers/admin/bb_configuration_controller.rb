class Admin::BbConfigurationController < AdminController
  def edit
    json = BbConfig.getJson
    @boxes = json["boxes"]
  end

  def update
    json_array = Array.new
    # build json array
    params[:weight].each_with_index do |value, indx|
      json_array << {
        name: params[:name][indx],
        weight: params[:weight][indx].to_f, 
        height: params[:height][indx].to_f,
        width: params[:width][indx].to_f, 
        lenght: params[:lenght][indx].to_f
      }
    end
    # order from bigger to smaller using weight as reference
    json_array.sort!{|a, b| b[:weight] <=> a[:weight]}

    if BbConfig.setBoxes(json_array) # save to file
      flash[:success] = "configuración guardada"
    else
      flash[:info] = "ocurrió un error al guardar"
    end

    redirect_to edit_admin_bb_configuration_path(:boxes)
  end
end
