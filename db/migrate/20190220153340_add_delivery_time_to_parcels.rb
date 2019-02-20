class AddDeliveryTimeToParcels < ActiveRecord::Migration[5.1]
  def change
    add_column :parcels, :delivery_time, :string
  end
end
