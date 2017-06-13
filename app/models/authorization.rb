class Authorization
  attr_accessor :valid
  attr_accessor :links
  attr_accessor :current_view_actions

  def isValid?
    return self.valid
  end

  def isValid(valid)
    self.valid = valid
  end
end
