class Order < ApplicationRecord
  belongs_to :City, foreign_key: :city_id, optional: true
  belongs_to :Distributor, foreign_key: :distributor_id, optional: true
  belongs_to :Client, foreign_key: :client_id, optional: true
  belongs_to :Parcel, foreign_key: :parcel_id, optional: true
  belongs_to :Warehouse, foreign_key: :warehouse_id, optional: true
  has_many :Details, class_name: :OrderDetail, foreign_key: :order_id
  has_many :Actions, class_name: :OrderAction, foreign_key: :order_id

  validates :client_id, :city_id, :distributor_id,
  :total, presence: true, on: :create

  validates :client_id, :distributor_id,
  numericality: { only_integer: true }, on: :create

  validates :total, numericality: true, on: :create

  mount_uploader :pay_img, PayUploader
  mount_uploader :pay_pdf, PdfUploader

  def self.byWarehouse(warehouse)
    return all unless warehouse
    raise ArgumentError, "warehouse must be an integer" unless warehouse.kind_of? Integer

    where(warehouse_id: warehouse)
  end

  def address_hash
    eval self.address
  end
  
  def address_for_google
    hash = address_hash
    str = "#{hash[:street]}+#{hash[:extnumber]}"
    str += "+interior+#{hash[:intnumber]}" if hash[:intnumber].present?
    str += "+#{hash[:col]}+#{hash[:cp]}"
    return str
  end
end
