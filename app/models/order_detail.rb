class OrderDetail < ActiveRecord::Base
  belongs_to :Order, :foreign_key => :order_id
  belongs_to :Product, :foreign_key => :product_id

  validates :order_id, :product_id, :quantity, :w_product_id,
            presence: true, numericality: { only_integer: true }
  validates :sub_total, presence: true, numericality: true
end
