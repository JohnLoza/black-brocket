class Parcel < ApplicationRecord
  has_many :Prices, class_name: :ParcelPrice, foreign_key: :parcel_id
  mount_uploader :image, AvatarUploader

  scope :local_delivery, -> { where(local_delivery: true) }
  scope :exclude_local_delivery, -> { where(local_delivery: false) }
end
