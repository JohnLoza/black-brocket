class ChangeOrdersAddressColumn < ActiveRecord::Migration[5.1]
  def change
    change_column :orders, :address, :text

    orders = Order.all.includes(:Client)
    orders.each do |order|
      client = order.Client
      address = {street: client.street, extnumber: client.extnumber,
        intnumber: client.intnumber, col: client.col,
        cp: client.cp, street_ref1: client.street_ref1,
        street_ref2: client.street_ref2, city_id: client.city_id}
      order.address = address
      order.save
    end
  end
end
