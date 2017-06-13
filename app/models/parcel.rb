class Parcel < ActiveRecord::Base
  mount_uploader :image, AvatarUploader
end
