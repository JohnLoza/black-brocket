class User

  # Returns the hash digest of the given string.
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # Returns a random token.
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  # Returns true if the given token matches the digest.
  def User.authenticated?(user, attribute, token)
    digest = user.send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  # Forgets a user.
  def User.forget(user)
    user.update_attribute(:remember_digest, nil)
  end

  # Get the user image if there is one, else return default image #
  def User.getImage(user, type = nil)
    image = ""
    if !user.photo.blank?
      if !type.nil?
        image = user.photo.url(type)
      else
        image = user.photo.url
      end
    else
      image = "user_avatar.png"
    end # if !self.photo.blank? #
  end # def getImage(type = nil) #

end
