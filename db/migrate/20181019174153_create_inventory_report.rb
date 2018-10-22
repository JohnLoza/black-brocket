class CreateInventoryReport < ActiveRecord::Migration[5.1]
  def change
    create_table :inventory_reports do |t|
      t.bigint :worker_id
      t.bigint :warehouse_id
      t.bigint :product_id
      t.string :batch
      t.text :comment
      t.boolean :done, default: false

      t.timestamps
    end

    add_index :inventory_reports, :worker_id
    add_index :inventory_reports, :warehouse_id
    add_index :inventory_reports, :product_id
  end
end
