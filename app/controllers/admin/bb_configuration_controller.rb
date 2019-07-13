class Admin::BbConfigurationController < AdminController
  def index
  end

  def boxes
    begin
      @boxes = Box.all
    rescue JSON::ParserError
      @boxes = Hash.new
      # rescue JSON::ParserError
    rescue Errno::ENOENT
      directory = File.join(File.dirname(__FILE__), '../../../config/black_brocket')
      Dir.mkdir(directory) unless Dir.exist?(directory)
      # rescue Errno::ENOENT
    end # begin end
  end

  def set_boxes
    json_array = Array.new

    # build json array
    params[:weight].each_with_index do |value, indx|
      json_array << {
        name: params[:name][indx],
        weight: params[:weight][indx].to_f, 
        height: params[:height][indx].to_f,
        width: params[:width][indx].to_f, 
        length: params[:length][indx].to_f
      }
    end

    Box.setBoxes(json_array)
    flash[:success] = "Cajas guardadas"
    redirect_to admin_boxes_configuration_path()
  end

end
