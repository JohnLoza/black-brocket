class Order < ApplicationRecord
  belongs_to :City, foreign_key: :city_id
  belongs_to :Distributor, foreign_key: :distributor_id
  belongs_to :Client, foreign_key: :client_id
  has_many :Details, class_name: :OrderDetail, foreign_key: :order_id
  has_many :Actions, class_name: :OrderAction, foreign_key: :order_id
  belongs_to :Parcel, foreign_key: :parcel_id
  belongs_to :Warehouse, foreign_key: :warehouse_id

  validates :client_id, :city_id, :distributor_id,
  :total, presence: true, :on => :create

  validates :client_id, :distributor_id,
  numericality: { only_integer: true }, :on => :create

  validates :total, numericality: true, :on => :create

  mount_uploader :pay_img, PayUploader
  mount_uploader :pay_pdf, PdfUploader
end
