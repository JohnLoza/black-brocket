# rake db:create
# rake db:migrate
# rake db:migrate RAILS_ENV=production --trace

class CreateDbTables < ActiveRecord::Migration
  def change
    # bank_accounts #
    create_table :bank_accounts do |t|
      t.string :bank_name
      t.string :account_number
      t.string :owner

      t.timestamps
    end
    # bank_accounts #

    # cities #
    create_table :cities do |t|
      t.integer :state_id
      t.string :alph_key
      t.string :name

      t.timestamps
    end
    add_index :cities, :alph_key, unique: true
    # cities #

    # clients #
    create_table :clients do |t|
      t.integer :city_id
      t.string :alph_key
      t.string :email
      t.boolean :email_verified, default: false
      t.string :username, unique: true
      t.string :password_digest
      t.string :street
      t.string :intnumber
      t.string :extnumber
      t.string :col
      t.string :cp
      t.string :street_ref1
      t.string :street_ref2
      t.string :telephone
      t.string :cellphone
      t.string :bank_reference
      t.string :remember_digest
      t.string :recover_pass_digest
      t.string :validate_email_digest
      t.string :photo
      t.boolean :deleted, :default => false

      t.timestamps
    end
    add_index :clients, :alph_key, unique: true
    # clients #

    # countries #
    create_table :countries do |t|
      t.string :alph_key
      t.string :name

      t.timestamps
    end
    add_index :countries, :alph_key, unique: true
    # countries #

    # distributors #
    create_table :distributors do |t|
      t.integer :city_id
      t.string :alph_key
      t.string :name
      t.string :lastname
      t.string :mother_lastname
      t.string :email
      t.string :username, unique: true
      t.string :password_digest
      t.string :rfc
      t.string :fiscal_number
      t.string :address
      t.string :telephone
      t.string :cellphone
      t.string :remember_digest
      t.string :recover_pass_digest
      t.string :photo
      t.boolean :deleted, :default => false

      t.timestamps
    end
    add_index :distributors, :alph_key, unique: true
    # distributors #

    # distributor_regions @deprecated #
    create_table :distributor_regions, :id => false do |t|
      t.integer :distributor_id
      t.integer :city_id
    end
    # distributor_regions #

    # fiscal_data #
    create_table :fiscal_data do |t|
      t.integer :client_id
      t.integer :city_id
      t.string :alph_key
      t.string :rfc
      t.string :name
      t.string :lastname
      t.string :mother_lastname
      t.string :street
      t.string :intnumber
      t.string :extnumber
      t.string :col
      t.string :cp

      t.timestamps
    end
    add_index :fiscal_data, :alph_key, unique: true
    # fiscal_data #

    # notifications #
    create_table :notifications do |t|
      t.integer :client_id
      t.string :icon
      t.string :url
      t.string :description
      t.boolean :seen, default: false

      t.timestamps
    end
    # notifications #

    # orders #
    create_table :orders do |t|
      t.integer :client_id
      t.integer :city_id
      t.integer :distributor_id
      t.string :alph_key
      t.string :address
      t.decimal :total, precision: 8, scale: 2
      t.string :pay_img
      t.string :pay_pdf, default: nil
      t.string :tracking_code
      t.string :state
      t.boolean :invoice, :default => false
      t.boolean :invoice_sent, :default => false
      t.boolean :direct_to_client, :default => false

      t.timestamps
    end
    add_index :orders, :alph_key, unique: true
    # orders #

    # order_details #
    create_table :order_details do |t|
      t.integer :order_id
      t.integer :product_id
      t.integer :w_product_id
      t.string :alph_key
      t.integer :quantity
      t.decimal :sub_total, precision: 8, scale: 2

      t.timestamps
    end
    add_index :order_details, :alph_key, unique: true
    # order_details #

    # permissions #
      create_table :permissions do |t|
        t.integer :worker_id
        t.string :category
        t.string :name
      end
      add_index :permissions, [:worker_id, :category]
    # permissions #

    # prod_answers #
    create_table :prod_answers do |t|
      t.integer :question_id
      t.integer :site_worker_id
      t.text :description

      t.timestamps
    end
    # prod_answers #

    # prod_photos #
    create_table :prod_photos do |t|
      t.integer :product_id
      t.string :alph_key
      t.string :photo
      t.boolean :is_principal, :default => false

      t.timestamps
    end
    add_index :prod_photos, :alph_key, unique: true
    # prod_photos #

    # prod_questions #
    create_table :prod_questions do |t|
      t.integer :product_id
      t.integer :client_id
      t.string :alph_key
      t.text :description
      t.boolean :answered, default: false

      t.timestamps
    end
    add_index :prod_questions, :alph_key, unique: true
    # prod_questions #

    # products #
    create_table :products do |t|
      t.string :alph_key
      t.string :name
      t.text :description
      t.decimal :price, precision: 8, scale: 2
      t.decimal :lowest_price, precision: 8, scale: 2
      t.boolean :show, default: false
      t.decimal :shipping_cost, precision: 8, scale: 2
      t.string :video
      t.text :preparation
      t.boolean :hot, :default => false
      t.boolean :cold, :default => false
      t.boolean :frappe, :default => false
      t.boolean :deleted, :default => false

      t.timestamps
    end
    add_index :products, :alph_key, unique: true
    # products #

    # site_workers #
    create_table :site_workers do |t|
      t.integer :city_id
      t.integer :warehouse_id
      t.string :alph_key
      t.string :name
      t.string :lastname
      t.string :mother_lastname
      t.string :email
      t.string :username, unique: true
      t.string :password_digest
      t.string :rfc
      t.string :nss
      t.string :address
      t.string :telephone
      t.string :cellphone
      t.boolean :is_admin, default: false
      t.string :remember_digest
      t.string :recover_pass_digest
      t.string :photo
      t.boolean :deleted, :default => false

      t.timestamps
    end
    add_index :site_workers, :alph_key, unique: true
    # site_workers #

    # social_networks #
    create_table :social_networks do |t|
      t.string :name
      t.string :icon
      t.string :url

      t.timestamps
    end

    SocialNetwork.create({
      name: "FACEBOOK",
      icon: "<i class='fa fa-facebook fa-23px'></i>",
      url: "https://www.facebook.com/"
      })

    SocialNetwork.create({
      name: "TWITTER",
      icon: "<i class='fa fa-twitter fa-23px'></i>",
      url: "https://twitter.com/"
      })

    SocialNetwork.create({
      name: "GOOGLE+",
      icon: "<i class='fa fa-google-plus fa-23px'></i>",
      url: "https://plus.google.com/"
      })

    SocialNetwork.create({
      name: "YOUTUBE",
      icon: "<i class='fa fa-youtube fa-23px'></i>",
      url: "https://www.youtube.com/"
      })

    SocialNetwork.create({
      name: "PINTEREST",
      icon: "<i class='fa fa-pinterest fa-23px'></i>",
      url: "https://es.pinterest.com/"
      })

    SocialNetwork.create({
      name: "INSTAGRAM",
      icon: "<i class='fa fa-instagram fa-23px'></i>",
      url: "https://instagram.com/"
      })
    # social_networks #

    # suggestions #
    create_table :suggestions do |t|
      t.string :name
      t.string :email
      t.text :message
      t.text :response
      t.boolean :answered, default: false

      t.timestamps
    end
    # suggestions #

    # states #
    create_table :states do |t|
      t.integer :country_id
      t.string :alph_key
      t.string :name
    end
    add_index :states, :alph_key, unique: true
    # states #

    # warehouses #
    create_table :warehouses do |t|
      t.integer :city_id
      t.string :alph_key
      t.string :name
      t.string :address
      t.string :telephone
      t.boolean :is_central
      t.boolean :deleted, :default => false

      t.timestamps
    end
    add_index :warehouses, :alph_key, unique: true
    # warehouses #

    # warehouse_products #
    create_table :warehouse_products do |t|
      t.string :alph_key
      t.integer :warehouse_id
      t.integer :product_id
      t.integer :existence, default: 0
      t.integer :min_stock
    end
    # warehouse_products #

    # warehouse_regions @deprecated #
    create_table :warehouse_regions, :id => false do |t|
      t.integer :warehouse_id
      t.integer :state_id
    end
    # warehouse_regions #

    # web_info #
    create_table :web_infos do |t|
      t.string :name
      t.text :description
      t.boolean :active

      t.timestamps
    end
    # web_info #

    # web_offers #
    create_table :web_offers do |t|
      t.string :photo
      t.string :url

      t.timestamps
    end
    # web_offers #

    # web_photos #
    create_table :web_photos do |t|
      t.string :name
      t.string :photo
      t.boolean :active

      t.timestamps
    end
    # web_photos #

    # web_videos #
    create_table :web_videos do |t|
      t.string :name
      t.string :video
      t.boolean :active

      t.timestamps
    end
    # web_videos #
  end
end
