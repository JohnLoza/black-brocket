class WebOffer < ActiveRecord::Base
  validates :url, :photo, presence: true

  mount_uploader :photo, ImageUploader
end
