class AddLocalDeliveryToParcels < ActiveRecord::Migration[5.1]
  def change
    add_column :parcels, :local_delivery, :boolean, default: false
  end
end
