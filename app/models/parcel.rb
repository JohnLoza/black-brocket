class Parcel < ApplicationRecord
  has_many :Prices, class_name: :ParcelPrice, foreign_key: :parcel_id
  mount_uploader :image, AvatarUploader
end
