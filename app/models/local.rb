class Local
  @@FILE_PATH = "config/black_brocket/locals.json"

  def self.all()
    JSON.parse File.read(@@FILE_PATH)
  end

  def self.setLocals(json)
    # File.write(@@FILE_PATH, JSON.pretty_generate(json))
    File.write(@@FILE_PATH, json.to_json)
  end

  def self.forLocation(location)
    raise ArgumentError, "location must be an Integer" unless location.kind_of? Integer
    locals = self.all.select{|key, hash| hash["cities"].include? location }

    return locals.values[0] || nil
  end
end
