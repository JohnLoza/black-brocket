class AddDiscountToOrderDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :order_details, :discount, :decimal, precision: 5, scale: 2
  end
end
