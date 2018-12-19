# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20181019174153) do

  create_table "bank_accounts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "bank_name"
    t.string "account_number"
    t.string "owner"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "interbank_clabe"
    t.string "email"
    t.string "RFC"
    t.integer "bank_id"
  end

  create_table "bank_report_views", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "worker_id"
    t.date "from_date"
    t.date "to_date"
    t.string "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "banks", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "owner"
    t.string "email"
    t.string "RFC"
    t.string "image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cities", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "state_id"
    t.bigint "distributor_id"
    t.string "name"
    t.string "lada"
    t.index ["distributor_id"], name: "index_cities_on_distributor_id"
    t.index ["state_id"], name: "index_cities_on_state_id"
  end

  create_table "client_distributor_comments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "client_id"
    t.integer "distributor_id"
    t.text "comment"
    t.boolean "is_from_client"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "worker_id"
  end

  create_table "client_products", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "client_id"
    t.integer "product_id"
    t.decimal "client_price", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "clients", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "city_id"
    t.string "hash_id", null: false
    t.string "email"
    t.boolean "email_verified", default: false
    t.string "username"
    t.string "password_digest"
    t.string "street"
    t.string "intnumber"
    t.string "extnumber"
    t.string "col"
    t.string "cp"
    t.string "street_ref1"
    t.string "street_ref2"
    t.string "telephone"
    t.string "cellphone"
    t.string "bank_reference"
    t.string "remember_digest"
    t.string "recover_pass_digest"
    t.string "validate_email_digest"
    t.string "photo"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_supervisor_visit"
    t.boolean "is_new", default: true
    t.integer "worker_id"
    t.datetime "last_distributor_revision"
    t.datetime "last_distributor_visit"
    t.boolean "has_custom_prices", default: false
    t.date "birthday"
    t.string "delete_account_hash"
    t.string "name"
    t.string "lastname"
    t.string "mother_lastname"
    t.string "authentication_token"
    t.index ["deleted_at"], name: "index_clients_on_deleted_at"
    t.index ["hash_id"], name: "index_clients_on_hash_id", unique: true
  end

  create_table "commission_details", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "commission_id"
    t.integer "order_id"
  end

  create_table "commissions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "hash_id", null: false
    t.integer "distributor_id"
    t.integer "worker_id"
    t.decimal "total", precision: 8, scale: 2
    t.string "payment_img"
    t.string "payment_pdf"
    t.string "invoice"
    t.string "payment_day"
    t.string "state"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "invoice_downloaded", default: false
    t.index ["deleted_at"], name: "index_commissions_on_deleted_at"
    t.index ["hash_id"], name: "index_commissions_on_hash_id", unique: true
  end

  create_table "distributor_candidates", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "city_id"
    t.string "name"
    t.string "lastname"
    t.string "mother_lastname"
    t.string "email"
    t.string "telephone"
    t.string "cellphone"
    t.boolean "read", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "distributor_client_revisions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "distributor_id"
    t.integer "client_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "distributor_supervisions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "supervisor_id"
    t.integer "distributor_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "distributor_visits", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "distributor_id"
    t.integer "client_id"
    t.date "visit_date"
    t.boolean "client_recognizes_visit"
    t.string "treatment_answer"
    t.text "extra_comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "distributors", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "city_id"
    t.string "hash_id", null: false
    t.string "name"
    t.string "lastname"
    t.string "mother_lastname"
    t.string "email"
    t.string "username"
    t.string "password_digest"
    t.string "rfc"
    t.string "fiscal_number"
    t.string "address"
    t.string "telephone"
    t.string "cellphone"
    t.string "remember_digest"
    t.string "recover_pass_digest"
    t.string "photo"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "commission", precision: 5, scale: 2
    t.datetime "last_supervision"
    t.string "bank_name"
    t.string "bank_account_owner"
    t.string "bank_account_number"
    t.string "interbank_clabe"
    t.boolean "show_address", default: false
    t.string "home_img"
    t.date "birthday"
    t.string "authentication_token"
    t.index ["deleted_at"], name: "index_distributors_on_deleted_at"
    t.index ["hash_id"], name: "index_distributors_on_hash_id", unique: true
  end

  create_table "fiscal_data", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "client_id"
    t.integer "city_id"
    t.string "hash_id", null: false
    t.string "rfc"
    t.string "name"
    t.string "lastname"
    t.string "mother_lastname"
    t.string "street"
    t.string "intnumber"
    t.string "extnumber"
    t.string "col"
    t.string "cp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hash_id"], name: "index_fiscal_data_on_hash_id", unique: true
  end

  create_table "footer_extra_details", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.text "detail"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "inventory_reports", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "worker_id"
    t.bigint "warehouse_id"
    t.bigint "product_id"
    t.string "batch"
    t.text "comment"
    t.boolean "done", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_inventory_reports_on_product_id"
    t.index ["warehouse_id"], name: "index_inventory_reports_on_warehouse_id"
    t.index ["worker_id"], name: "index_inventory_reports_on_worker_id"
  end

  create_table "notifications", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "client_id"
    t.string "icon"
    t.string "url"
    t.string "description"
    t.boolean "seen", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "distributor_id"
    t.integer "worker_id"
  end

  create_table "order_actions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "order_id"
    t.integer "worker_id"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_details", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "order_id"
    t.integer "product_id"
    t.integer "w_product_id"
    t.string "hash_id", null: false
    t.integer "quantity"
    t.decimal "sub_total", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "price", precision: 8, scale: 2
    t.decimal "iva", precision: 5, scale: 2
    t.decimal "ieps", precision: 5, scale: 2
    t.decimal "total_iva", precision: 8, scale: 2
    t.decimal "total_ieps", precision: 8, scale: 2
    t.index ["hash_id"], name: "index_order_details_on_hash_id", unique: true
  end

  create_table "order_product_shipment_details", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "order_id"
    t.integer "product_id"
    t.integer "quantity"
    t.string "batch"
  end

  create_table "orders", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "client_id"
    t.integer "city_id"
    t.integer "distributor_id"
    t.string "hash_id", null: false
    t.string "address"
    t.decimal "total", precision: 8, scale: 2
    t.string "pay_img"
    t.string "pay_pdf"
    t.string "tracking_code"
    t.string "state"
    t.boolean "invoice", default: false
    t.boolean "invoice_sent", default: false
    t.boolean "direct_to_client", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "commission_in_progress", default: false
    t.integer "warehouse_id"
    t.integer "freight_worker_id"
    t.integer "parcel_id"
    t.text "reject_description"
    t.text "cancel_description"
    t.decimal "shipping_cost", precision: 8, scale: 2
    t.string "download_payment_key"
    t.integer "payment_method"
    t.string "payment_folio"
    t.index ["hash_id"], name: "index_orders_on_hash_id", unique: true
    t.index ["payment_folio"], name: "index_orders_on_payment_folio", unique: true
  end

  create_table "parcels", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "warehouse_id"
    t.string "parcel_name"
    t.decimal "cost", precision: 8, scale: 2
    t.string "tracking_url"
    t.string "image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "permissions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "worker_id"
    t.string "category"
    t.string "name"
    t.boolean "supervisor", default: false
    t.boolean "warehouse_chief", default: false
    t.index ["worker_id", "category"], name: "index_permissions_on_worker_id_and_category"
  end

  create_table "prod_answers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "question_id"
    t.integer "site_worker_id"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "prod_photos", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "product_id"
    t.string "hash_id", null: false
    t.string "photo"
    t.boolean "is_principal", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hash_id"], name: "index_prod_photos_on_hash_id", unique: true
  end

  create_table "prod_questions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "product_id"
    t.integer "client_id"
    t.string "hash_id", null: false
    t.text "description"
    t.boolean "answered", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hash_id"], name: "index_prod_questions_on_hash_id", unique: true
  end

  create_table "products", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "hash_id", null: false
    t.string "name"
    t.string "description_render_path"
    t.decimal "price", precision: 8, scale: 2
    t.decimal "lowest_price", precision: 8, scale: 2
    t.boolean "show", default: false
    t.decimal "shipping_cost", precision: 8, scale: 2
    t.string "video"
    t.string "preparation_render_path"
    t.boolean "hot", default: false
    t.boolean "cold", default: false
    t.boolean "frappe", default: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "presentation"
    t.decimal "recommended_price", precision: 8, scale: 2
    t.decimal "ieps", precision: 5, scale: 2
    t.decimal "iva", precision: 5, scale: 2
    t.index ["deleted_at"], name: "index_products_on_deleted_at"
    t.index ["hash_id"], name: "index_products_on_hash_id", unique: true
  end

  create_table "shipment_details", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "shipment_id"
    t.integer "product_id"
    t.integer "quantity"
    t.string "batch"
    t.string "expiration_date"
  end

  create_table "shipment_difference_report_details", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "difference_report_id"
    t.integer "shipment_detail_id"
    t.integer "difference"
  end

  create_table "shipment_difference_reports", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "shipment_id"
    t.integer "worker_id"
    t.integer "chief_id"
    t.boolean "reviewed", default: false
    t.text "observations"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shipments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "origin_warehouse_id"
    t.integer "target_warehouse_id"
    t.integer "chief_id"
    t.integer "worker_id"
    t.integer "freight_worker_id"
    t.boolean "got_safe_to_destination"
    t.string "shipment_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "reviewed", default: false
  end

  create_table "site_workers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "city_id"
    t.integer "warehouse_id"
    t.string "hash_id", null: false
    t.string "name"
    t.string "lastname"
    t.string "mother_lastname"
    t.string "email"
    t.string "username"
    t.string "password_digest"
    t.string "rfc"
    t.string "nss"
    t.string "address"
    t.string "telephone"
    t.string "cellphone"
    t.boolean "is_admin", default: false
    t.string "remember_digest"
    t.string "recover_pass_digest"
    t.string "photo"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "birthday"
    t.string "authentication_token"
    t.index ["deleted_at"], name: "index_site_workers_on_deleted_at"
    t.index ["hash_id"], name: "index_site_workers_on_hash_id", unique: true
  end

  create_table "social_networks", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "icon"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "states", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "warehouse_id"
    t.string "name"
    t.index ["warehouse_id"], name: "index_states_on_warehouse_id"
  end

  create_table "suggestions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "email"
    t.text "message"
    t.text "response"
    t.boolean "answered", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "supervisor_visit_details", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "visit_id"
    t.string "client_type"
    t.string "location"
    t.string "local_size"
    t.string "instalations"
    t.string "infrastructure"
    t.string "visibility"
    t.string "motor_traffic"
    t.string "walker_traffic"
    t.text "global_profile"
    t.string "years_commerce"
    t.string "consumers"
    t.string "client_clients_opinion_our_product"
    t.string "client_clients_opinion_his_products"
    t.string "client_clients_opinion_his_service"
    t.string "client_workers"
    t.string "client_branches"
    t.text "global_commerce"
    t.string "product_quality"
    t.string "product_assortment"
    t.string "product_price"
    t.string "product_taste"
    t.string "product_packing"
    t.string "packing_aspect"
    t.string "product_expiration"
    t.string "product_shipping_packing"
    t.string "need_new_products"
    t.string "visits"
    t.string "worker_uniform"
    t.string "distributor"
    t.string "worker"
    t.string "shipment"
    t.string "shipment_time"
    t.text "global_service"
    t.string "web_easy"
    t.string "purchase_system"
    t.string "payment_system"
    t.string "purchase_follow_up"
    t.string "global_web"
    t.text "extra_comments"
  end

  create_table "supervisor_visits", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "worker_id"
    t.integer "client_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tip_recipe_comments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "tip_recipe_id"
    t.integer "client_id"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tip_recipes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "title"
    t.string "description_render_path"
    t.string "image"
    t.string "video"
    t.string "video_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "warehouse_products", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "hash_id", null: false
    t.integer "warehouse_id"
    t.integer "product_id"
    t.integer "existence", default: 0
    t.integer "min_stock"
    t.string "batch"
    t.date "expiration_date"
    t.boolean "describes_total_stock", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["hash_id"], name: "index_warehouse_products_on_hash_id", unique: true
  end

  create_table "warehouses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "city_id"
    t.string "hash_id", null: false
    t.string "name"
    t.string "address"
    t.string "telephone"
    t.boolean "is_central"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "shipping_cost", precision: 8, scale: 2
    t.decimal "wholesale", precision: 8, scale: 2
    t.index ["deleted_at"], name: "index_warehouses_on_deleted_at"
    t.index ["hash_id"], name: "index_warehouses_on_hash_id", unique: true
  end

  create_table "web_infos", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "description_render_path"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "web_offers", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "photo"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "web_photos", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "photo"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "web_videos", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "video"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "cities", "distributors"
end
