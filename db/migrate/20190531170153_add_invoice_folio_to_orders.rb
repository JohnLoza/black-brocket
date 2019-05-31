class AddInvoiceFolioToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :invoice_folio, :string
  end
end
