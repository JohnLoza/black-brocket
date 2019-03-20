class AddGuidesToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :guides, :string
  end
end
