class ShipmentDetail < ApplicationRecord
  attr_accessor :type
  attr_accessor :origin_warehouse_id
  attr_accessor :target_warehouse_id

  after_save :updateStock

  belongs_to :Shipment, foreign_key: :shipment_id, optional: true
  belongs_to :Product, foreign_key: :product_id, optional: true

  validate :batchDoesntRepeat
  validate :productMustExistForTransfer

  private
    def batchDoesntRepeat
      warehouse_product = WarehouseProduct.where(batch: batch)
        .where(warehouse_id: target_warehouse_id).take
      if warehouse_product
        errors.add(:batch, "Batch must not be repeated (#{batch})")
      end
    end

    def productMustExistForTransfer
      return unless type == "TRANSFER"
      warehouse_product = WarehouseProduct.where(batch: batch)
        .where(warehouse_id: origin_warehouse_id).take
      unless warehouse_product
        errors.add(:product_id, "Product doesnt exist and is needed for transfer")
      end
    end

    def updateStock
      return unless type == "TRANSFER"
      master_product = WarehouseProduct.where(warehouse_id: origin_warehouse_id,
        product_id: product_id, describes_total_stock: true).take
      master_product.withdraw(quantity)

      product = WarehouseProduct.where(
        warehouse_id: origin_warehouse_id, product_id: product_id, batch: batch).take
      product.withdraw(quantity)
    end
end
