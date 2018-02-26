class WebOffer < ApplicationRecord
  validates :url, :photo, presence: true

  mount_uploader :photo, ImageUploader
end
