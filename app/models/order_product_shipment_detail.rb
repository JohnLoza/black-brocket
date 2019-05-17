class OrderProductShipmentDetail < ApplicationRecord
  attr_accessor :warehouse_detail
  attr_accessor :warehouse_id

  belongs_to :Order, class_name: :Order, foreign_key: :order_id

  validate :warehouse_product_exists
  validate :warehouse_product_has_enough_stock

  private
    def warehouse_product_exists
      product_detail = WarehouseProduct.where(warehouse_id: warehouse_id,
        product_id: product_id, batch: batch).take
      self.warehouse_detail = product_detail
      # add an error if the product with the given key and batch doesn't exist #
      unless product_detail
        errors.add(:warehouse_detail, "No existe el producto #{product_id} con lote #{batch}")
      end
    end

    def warehouse_product_has_enough_stock
      return unless self.warehouse_detail
      # if the current existence of the product is less than the one captured stop the execution #
      unless self.warehouse_detail.existence >= quantity
        errors.add(:quantity, "No hay existencias suficientes para el producto #{product_id} con lote #{batch}")
      end
    end
end
