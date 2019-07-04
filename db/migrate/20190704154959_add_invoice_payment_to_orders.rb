class AddInvoicePaymentToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :invoice_payment, :string
  end
end
