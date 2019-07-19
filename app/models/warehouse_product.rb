class WarehouseProduct < ApplicationRecord
  attr_accessor :required_bulk
  attr_accessor :required_quantity
  include HashId
  include Searchable
  
  belongs_to :Warehouse, foreign_key: :warehouse_id
  belongs_to :Product, foreign_key: :product_id

  validates :warehouse_id, :product_id, :existence, presence: true,
    numericality: { only_integer: true }, on: :create

  scope :visible, -> { where(products: {show: true}) }
  scope :active, -> { where(products: {deleted_at: nil})}
  scope :describes_total_stock, -> { where(describes_total_stock: true)}

  def self.by_category(category)
    return all unless category.present? and ["hot","cold","frappe"].include? category
    where("products.#{category}" => true)
  end

  def enoughStock?
    return true if self.existence >= self.required_quantity
    return false
  end

  def withdraw(quantity)
    self.required_quantity = quantity
    raise StandardError, "Sin stock suficiente" unless self.enoughStock?
    update_attributes(existence: self.existence - required_quantity)
  end

  def supply(to_be_added)
    update_attributes(existence: self.existence + to_be_added)
  end

  def self.return(product_id, quantity)
    query = "UPDATE warehouse_products 
      SET existence=(existence+#{quantity}) WHERE
      id=#{product_id}"
    ActiveRecord::Base.connection.execute(query)
  end
end
