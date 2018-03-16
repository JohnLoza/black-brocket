class ProdPhoto < ApplicationRecord
  include HashId

  belongs_to :Product, foreign_key: :product_id

  validates :product_id, numericality: { only_integer: true }
  validates :product_id, :photo, presence: true

  mount_uploader :photo, ProductImageUploader

  scope :by_product, -> (product_id) { where(product_id: product_id) }
  scope :only_principal, -> { where(is_principal: true) }
  scope :not_principal, -> { where(is_principal: false) }
end
