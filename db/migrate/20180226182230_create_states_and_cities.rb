class CreateStatesAndCities < ActiveRecord::Migration[5.1]
  def change
    # states #
    create_table :states do |t|
      t.references :warehouse
      t.string :name
    end
    # states #

    # cities #
    create_table :cities do |t|
      t.references :state
      t.bigint :distributor_id
      t.string :name
      t.string :lada
    end
    add_index :cities, :distributor_id
    add_foreign_key :cities, :distributors, column: :distributor_id, primary_key: :id
    # distributor is actually a user
    # add_foreign_key :cities, :users, column: :distributor_id, primary_key: :id
    # cities #
  end
end
