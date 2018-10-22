class CreateTables2Version < ActiveRecord::Migration[5.1]
  def change
  # Commissions #
    create_table :commissions do |t|
      t.string :hash_id, null: false, collation: "utf8_bin"
      t.bigint :distributor_id
      t.bigint :worker_id
      t.decimal :total, precision: 8, scale: 2
      t.string :payment_img
      t.string :payment_pdf
      t.string :invoice
      t.string :payment_day
      t.string :state
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :commissions, :hash_id, unique: true
    add_index :commissions, :deleted_at

    create_table :commission_details do |t|
      t.bigint :commission_id
      t.bigint :order_id
    end

    add_column :distributors, :commission, :decimal, precision: 5, scale: 2
    add_column :orders, :commission_in_progress, :boolean, :default => false
  # Commisions #

  # Supervision #
    create_table :supervisor_visits do |t|
      t.bigint :worker_id
      t.bigint :client_id

      t.timestamps
    end

    create_table :supervisor_visit_details do |t|
      t.bigint :visit_id
      t.string :client_type
      # Profile #
      t.string :location
      t.string :local_size
      t.string :instalations
      t.string :infrastructure
      t.string :visibility
      t.string :motor_traffic
      t.string :walker_traffic
      t.text :global_profile
      # Commercial Valuation #
      t.string :years_commerce
      t.string :consumers
      t.string :client_clients_opinion_our_product
      t.string :client_clients_opinion_his_products
      t.string :client_clients_opinion_his_service
      t.string :client_workers
      t.string :client_branches
      t.text :global_commerce
      # Product Valuation #
      t.string :product_quality
      t.string :product_assortment
      t.string :product_price
      t.string :product_taste
      t.string :product_packing
      t.string :packing_aspect
      t.string :product_expiration
      t.string :product_shipping_packing
      t.string :need_new_products
      # Service Valuation #
      t.string :visits
      t.string :worker_uniform
      t.string :distributor
      t.string :worker
      t.string :shipment
      t.string :shipment_time
      t.text :global_service
      # Web Site Valuation #
      t.string :web_easy
      t.string :purchase_system
      t.string :payment_system
      t.string :purchase_follow_up
      t.string :global_web
      t.text :extra_comments
    end

    create_table :distributor_supervisions do |t|
      t.bigint :supervisor_id
      t.bigint :distributor_id

      t.timestamps
    end

    add_column :clients, :last_supervisor_visit, :datetime
    add_column :permissions, :supervisor, :boolean, :default => false
    add_column :distributors, :last_supervision, :datetime
  # Supervision #

  # New Distributor System #
    create_table :distributor_client_revisions do |t|
      t.bigint :distributor_id
      t.bigint :client_id

      t.timestamps
    end

    create_table :distributor_visits do |t|
      t.bigint :distributor_id
      t.bigint :client_id
      t.date :visit_date
      t.boolean :client_recognizes_visit
      t.string :treatment_answer
      t.text :extra_comments

      t.timestamps
    end

    create_table :client_products do |t|
      t.bigint :client_id
      t.bigint :product_id
      t.decimal :client_price, precision: 8, scale: 2

      t.timestamps
    end

    create_table :distributor_candidates do |t|
      t.bigint :city_id
      t.string :name
      t.string :lastname
      t.string :mother_lastname
      t.string :email
      t.string :telephone
      t.string :cellphone
    end

    create_table :client_distributor_comments do |t|
      t.bigint :client_id
      t.bigint :distributor_id
      t.text :comment
      t.boolean :is_from_client

      t.timestamps
    end

    add_column :distributors, :bank_name, :string
    add_column :distributors, :bank_account_owner, :string
    add_column :distributors, :bank_account_number, :string
    add_column :distributors, :interbank_clabe, :string
    add_column :distributors, :show_address, :boolean, :default => false
    add_column :distributors, :home_img, :string

    add_column :clients, :is_new, :boolean
    add_column :clients, :worker_id, :integer
    add_column :clients, :last_distributor_revision, :datetime
    add_column :clients, :last_distributor_visit, :datetime
    add_column :clients, :has_custom_prices, :boolean, :defalt => false
  # New Distributor System #

  # New Warehouses System Using Batches #
    create_table :shipments do |t|
      t.bigint :origin_warehouse_id
      t.bigint :target_warehouse_id
      t.bigint :chief_id
      t.bigint :worker_id
      t.bigint :freight_worker_id
      t.boolean :got_safe_to_destination
      t.string :shipment_type

      t.timestamps
    end

    create_table :shipment_details do |t|
      t.bigint :shipment_id
      t.bigint :product_id
      t.bigint :quantity
      t.string :batch
      t.string :expiration_date
    end

    create_table :shipment_difference_reports do |t|
      t.bigint :shipment_id
      t.bigint :worker_id
      t.bigint :chief_id
      t.boolean :reviewed, :default => false
      t.text :observations

      t.timestamps
    end

    create_table :shipment_difference_report_details do |t|
      t.bigint :difference_report_id
      t.bigint :shipment_detail_id
      t.bigint :difference
    end

    add_column :warehouses, :shipping_cost, :decimal, :precision => 8, :scale => 2
    add_column :warehouses, :wholesale, :decimal, :precision => 8, :scale => 2

    add_column :warehouse_products, :batch, :string
    add_column :warehouse_products, :expiration_date, :date
  # New Warehouses System Using Batches #

  # New Orders System #
    create_table :order_product_shipment_details do |t|
      t.bigint :order_id
      t.bigint :product_id
      t.bigint :quantity
      t.string :batch
    end

    create_table :parcels do |t|
      t.bigint :warehouse_id
      t.string :parcel_name
      t.decimal :cost, :precision => 8, :scale => 2
      t.string :tracking_url
      t.string :image

      t.timestamps
    end

    add_column :orders, :warehouse_id, :integer
    add_column :orders, :freight_worker_id, :integer
    add_column :orders, :parcel_id, :integer
    add_column :orders, :reject_description, :text
    add_column :orders, :cancel_description, :text
  # New Orders System #

  # Other #
    create_table :tip_recipes do |t|
      t.string :title
      t.text :description
      t.string :image
      t.string :video
      t.string :video_type

      t.timestamps
    end

    create_table :tip_recipe_comments do |t|
      t.bigint :tip_recipe_id
      t.bigint :client_id
      t.text :comment

      t.timestamps
    end

    create_table :footer_extra_details do |t|
      t.string :name
      t.text :detail

      t.timestamps
    end

    add_column :clients, :birthday, :date
    add_column :clients, :delete_account_hash, :string

    add_column :site_workers, :birthday, :date
    add_column :distributors, :birthday, :date

    add_column :bank_accounts, :interbank_clabe, :string

    add_column :products, :presentation, :string
    add_column :products, :recommended_price, :decimal, :precision => 8, :scale => 2
    add_column :products, :ieps, :decimal, :precision => 5, :scale => 2
    add_column :products, :iva, :decimal, :precision => 5, :scale => 2

    add_column :warehouse_products, :describes_total_stock, :boolean, :default => false
    add_column :permissions, :warehouse_chief, :boolean, :default => false

    add_column :warehouse_products, :created_at, :datetime
    add_column :warehouse_products, :updated_at, :datetime

    change_column :shipments, :got_safe_to_destination, :boolean, default: nil

    add_column :shipments, :reviewed, :boolean, :default => false

    add_column :bank_accounts, :email, :string
    add_column :bank_accounts, :RFC, :string

    add_column :clients, :name, :string
    add_column :clients, :lastname, :string
    add_column :clients, :mother_lastname, :string

    change_column :clients, :is_new, :boolean, :default => true
    change_column :clients, :has_custom_prices, :boolean, :default => false

    rename_column :tip_recipe_comments, :comment, :description

    add_column :distributor_candidates, :read, :boolean, :default => false

    add_column :client_distributor_comments, :worker_id, :integer

    add_column :notifications, :distributor_id, :integer
    add_column :notifications, :worker_id, :integer

    rename_column :commissions, :invoice, :invoice_img
    add_column :commissions, :invoice_pdf, :string

    create_table :order_actions do |t|
      t.bigint :order_id
      t.bigint :worker_id
      t.string :description

      t.timestamps
    end

    add_column :distributor_candidates, :created_at, :datetime
    add_column :distributor_candidates, :updated_at, :datetime

    rename_column :commissions, :invoice_img, :invoice
    remove_column :commissions, :invoice_pdf

    add_column :clients, :authentication_token, :string
    add_column :distributors, :authentication_token, :string
    add_column :site_workers, :authentication_token, :string

    add_column :commissions, :invoice_downloaded, :boolean, :default => false

    add_column :orders, :shipping_cost, :decimal, precision: 8, scale: 2

    add_column :order_details, :price, :decimal, precision: 8, scale: 2
    add_column :order_details, :iva, :decimal, precision: 5, scale: 2
    add_column :order_details, :ieps, :decimal, precision: 5, scale: 2
    add_column :order_details, :total_iva, :decimal, precision: 8, scale: 2
    add_column :order_details, :total_ieps, :decimal, precision: 8, scale: 2
  # Other #
  end
end
