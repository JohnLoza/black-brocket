class AddDescriptionToInventoryReports < ActiveRecord::Migration[5.1]
  def change
    add_column :inventory_reports, :description, :string
  end
end
