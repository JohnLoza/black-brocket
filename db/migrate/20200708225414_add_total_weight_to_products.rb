class AddTotalWeightToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :total_weight, :integer
  end
end
