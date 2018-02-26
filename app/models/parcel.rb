class Parcel < ApplicationRecord
  mount_uploader :image, AvatarUploader
end
