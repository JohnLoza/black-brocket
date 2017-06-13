class OrderProductShipmentDetail < ActiveRecord::Base
  belongs_to :Order, :class_name => :Order, :foreign_key => :order_id
end
