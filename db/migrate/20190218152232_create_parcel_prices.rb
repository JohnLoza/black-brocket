class CreateParcelPrices < ActiveRecord::Migration[5.1]
  def change
    add_column :products, :total_weight, :integer, default: 1535

    create_table :parcel_prices do |t|
      t.bigint :parcel_id
      t.integer :max_weight
      t.decimal :price, :precision => 8, :scale => 2
      t.timestamps
    end

    add_index :parcel_prices, :parcel_id
  end
end
