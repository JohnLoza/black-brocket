class BbConfig
  def self.getJson
    begin
      file_path = "config/black_brocket/black_brocket.json"
      JSON.parse File.read(file_path)
    rescue
      Hash.new
    end
  end

  def self.setJson(json)
    file_path = "config/black_brocket/black_brocket.json"

    begin
      # File.write(file_path, JSON.pretty_generate(json))
      File.write(file_path, json.to_json)
      return true
    rescue
      directory = File.join(File.dirname(__FILE__), '../../config/black_brocket')
      Dir.mkdir(directory) unless Dir.exist?(directory)
      setJson(json)
    end

    return false
  end

  def self.getBoxes()
    json = getJson
    json["boxes"]
  end

  def self.setBoxes(boxes_json)
    conf_json = getJson()
    conf_json[:boxes] = boxes_json
    
    if setJson(conf_json)
      return true
    else
      return false
    end
  end
end
