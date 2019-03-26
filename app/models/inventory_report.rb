class InventoryReport < ApplicationRecord
  belongs_to :Worker, class_name: :SiteWorker, foreign_key: :worker_id
  belongs_to :Warehouse, class_name: :Warehouse, foreign_key: :warehouse_id
  belongs_to :Product, class_name: :Product, foreign_key: :product_id

  validates :worker_id, :warehouse_id, :product_id, presence: true

  validates :batch, presence: true, length: { maximum: 20 }

  validates :description, presence: true, length: { maximum: 25 }
  validates :comment, length: { maximum: 1024 }
end
