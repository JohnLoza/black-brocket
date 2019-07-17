class ChangeOrdersGuidesColumn < ActiveRecord::Migration[5.1]
  def change
    change_column :orders, :guides, :text
  end
end
