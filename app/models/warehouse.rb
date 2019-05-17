class Warehouse < ApplicationRecord
  include HashId
  include Searchable
  include SoftDeletable

  belongs_to :City, foreign_key: :city_id
  has_many :Regions, class_name: 'State', foreign_key: :warehouse_id
  has_many :Products, class_name: 'WarehouseProduct', foreign_key: :warehouse_id

  has_many :TransferShipments, class_name: 'Shipment', foreign_key: :origin_warehouse_id
  has_many :IncomingShipments, class_name: 'Shipment', foreign_key: :target_warehouse_id

  has_many :Parcels, class_name: 'Parcel', foreign_key: :warehouse_id

  validates :city_id, :name, :address, :telephone, presence: true
  validates :city_id, numericality: { only_integer: true }

  scope :recent, -> { order(created_at: :desc) }
  scope :order_by_name, -> (way = nil) {
    way = :asc unless way.present?
    order(name: way)
  }

  def to_s
    name
  end

  def telephone_with_lada
    "(#{self.City.lada}) #{self.telephone}"
  end

  def location
    "#{self.City} #{self.City.State}"
  end

  def productsForApi(category, search)
    self.Products.joins(:Product).active.visible
      .describes_total_stock.by_category(category)
      .search(key_words: search, fields: ['products.name'])
      .includes(Product: :Photos)
  end
end
