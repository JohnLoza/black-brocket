class AddCfdiToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :cfdi, :string
  end
end
