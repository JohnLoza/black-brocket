class WarehouseProduct < ApplicationRecord
  include HashId
  include Searchable
  
  belongs_to :Warehouse, foreign_key: :warehouse_id
  belongs_to :Product, foreign_key: :product_id

  validates :warehouse_id, :product_id, :existence, presence: true,
                          numericality: { only_integer: true }, :on => :create

  scope :visible, -> { where(products: {show: true}) }
  scope :active, -> { where(products: {deleted_at: nil})}
  scope :describes_total_stock, -> { where(describes_total_stock: true)}

  def self.by_category(category)
    return all unless category.present? and ["hot","cold","frappe"].include? category
    where("products.#{category}" => true)
  end
end
