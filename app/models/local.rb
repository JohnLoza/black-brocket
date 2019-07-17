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
    location = location.to_s unless location.class == String
    locals = self.all.select{|key, hash| hash["cities"].has_key? location }

    return locals.values[0] || nil
  end
end
