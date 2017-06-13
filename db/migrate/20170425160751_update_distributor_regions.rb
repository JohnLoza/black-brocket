class UpdateDistributorRegions < ActiveRecord::Migration
  def change
    add_column :cities, :distributor_id, :integer

    regions = DistributorRegion.all
    regions.each do |region|
      city = region.City
      city.update_attribute(:distributor_id, region.distributor_id)
    end
  end
end
