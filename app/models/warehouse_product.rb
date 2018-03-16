class WarehouseProduct < ApplicationRecord
  include HashId
  
  belongs_to :Warehouse, foreign_key: :warehouse_id
  belongs_to :Product, foreign_key: :product_id

  validates :warehouse_id, :product_id, :existence, presence: true,
                          numericality: { only_integer: true }, :on => :create
end
