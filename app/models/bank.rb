class Bank < ApplicationRecord
  has_many :Accounts, class_name: 'BankAccount', dependent: :destroy

  mount_uploader :image, AvatarUploader
  validates :name, :owner, :email, :RFC, :image, presence: true
end
