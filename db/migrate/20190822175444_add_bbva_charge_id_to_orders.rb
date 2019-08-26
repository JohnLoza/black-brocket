class AddBbvaChargeIdToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :bbva_charge_id, :string
  end
end
