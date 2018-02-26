class ProdPhoto < ApplicationRecord
  belongs_to :Product, :foreign_key => :product_id

  validates :product_id, numericality: { only_integer: true }
  validates :product_id, :photo, presence: true

  mount_uploader :photo, ProductImageUploader
end
