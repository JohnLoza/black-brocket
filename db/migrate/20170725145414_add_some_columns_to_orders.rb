class AddSomeColumnsToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :download_payment_key, :string
    add_column :orders, :payment_method, :integer
    add_column :orders, :payment_folio, :string, unique: true
    add_index :orders, :payment_folio, unique: true

    Order.all.each do |order|
      if !order.pay_img.file.nil? or !order.pay_pdf.file.nil?
        order.update_attribute(:download_payment_key, SecureRandom.urlsafe_base64)
      end
    end
  end
end
