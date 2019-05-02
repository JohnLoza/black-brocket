require 'active_support/concern'

# For this concern to work, generate a migration for the model adding
# a datetime 'deleted_at' attribute with nil as default
module User
  extend ActiveSupport::Concern

  included do
    # attr_accessor :really_destroy
    # scope :active,   -> { where(deleted_at: nil) }
    # scope :inactive, -> { where.not(deleted_at: nil) }
  end

  def to_s
    full_name
  end

  # Returns a random token.
  def new_token
    SecureRandom.urlsafe_base64
  end

  # Returns the hash digest of the given string.
  def digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # Returns true if the given token matches the digest.
  def authenticated?(attribute, token)
    digest = self.send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  # Forgets a user.
  def forget
    self.update_attribute(:remember_digest, nil)
  end

  # Get the user image if there is one, else return default image #
  def avatar_url(type = nil)
    image = ""
    if self.photo.present?
      if !type.nil?
        image = self.photo.url(type)
      else
        image = self.photo.url
      end
    else
      image = ActionController::Base.helpers.image_url "user_avatar.png"
    end # if !self.photo.blank? #
  end # def getImage(type = nil) #

  def full_name
    "#{self.name} #{self.lastname} #{self.mother_lastname}"
  end

  def location
    "#{self.City} #{self.City.State}"
  end

  def telephone_with_lada
    "(#{self.City.lada}) #{self.telephone}"
  end

  def same_as?(another_user)
    self.hash_id == another_user.hash_id
  end

  def different_than?(another_user)
    self.hash_id != another_user.hash_id
  end

  class_methods do
    # class methods go here #
  end
end
