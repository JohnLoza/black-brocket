class WarehouseRegion < ApplicationRecord
  belongs_to :Warehouse, :foreign_key => :warehouse_id
  belongs_to :State, :foreign_key => :state_id

  validates :warehouse_id, :state_id, presence: true,
                                      numericality: { only_integer: true }
end
