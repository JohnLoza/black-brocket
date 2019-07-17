class Local
  @@FILE_PATH = "config/black_brocket/locals.json"

  def self.all()
    JSON.parse File.read(@@FILE_PATH)
  end

  def self.setLocals(json)
    begin
      # File.write(@@FILE_PATH, JSON.pretty_generate(json))
      File.write(@@FILE_PATH, json.to_json)
    rescue Errno::ENOENT
      directory = File.join(File.dirname(__FILE__), '../../config/black_brocket')
      Dir.mkdir(directory) unless Dir.exist?(directory)
      setBoxes(json)
    end
  end

  def self.forLocation(location)
    location = location.to_s unless location.class == String
    locals = self.all.select{|key, hash| hash["cities"].has_key? location }

    return locals.values[0] || nil
  end
end
