class UpdateWarehouseRegions < ActiveRecord::Migration
  def change
    add_column :states, :warehouse_id, :integer

    regions = WarehouseRegion.all
    regions.each do |region|
      state = region.State
      state.update_attribute(:warehouse_id, region.warehouse_id)
    end
  end
end
