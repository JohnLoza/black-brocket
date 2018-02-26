class CreateBank < ActiveRecord::Migration[5.1]
  def change
    create_table :banks do |t|
      t.string :name
      t.string :owner
      t.string :email
      t.string :RFC
      t.string :image

      t.timestamps
    end

    add_column :bank_accounts, :bank_id, :integer

    create_table :bank_report_views do |t|
      t.integer :worker_id
      t.date :from_date
      t.date :to_date
      t.string :details

      t.timestamps
    end
  end
end
