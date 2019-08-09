class AddConektaOrderIdToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :conekta_order_id, :string
  end
end
