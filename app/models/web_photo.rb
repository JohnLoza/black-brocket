class WebPhoto < ApplicationRecord
  validates :photo, presence: true

  mount_uploader :photo, ImageUploader

  # Get the user image if there is one, else return default image #
  def getImage(type = nil)
    image = ""
    if !self.photo.blank?
      if !type.nil?
        image = self.photo.url(type)
      else
        image = self.photo.url
      end
    else
      image = "person-woman-coffee-cup-large.jpg"
    end # if !self.photo.blank? #
  end # def getImage(type = nil) #
end
