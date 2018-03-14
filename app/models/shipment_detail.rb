class ShipmentDetail < ApplicationRecord
  belongs_to :Shipment, foreign_key: :shipment_id
  belongs_to :Product, foreign_key: :product_id
end
