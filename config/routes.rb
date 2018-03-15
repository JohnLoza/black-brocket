Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # static_pages #
  root 'static_pages#index'
  get '/good_bye/:id' => 'static_pages#good_bye', :as => :good_bye
  post '/' => 'static_pages#create_suggestion'

  get '/get_cities' => 'static_pages#get_cities', :as => :get_cities
  get '/get_city_lada' => 'static_pages#get_city_lada', :as => :get_city_lada
  get '/privacy_policy' => 'static_pages#privacy_policy', :as => :privacy_policy
  get '/terms_of_service' => 'static_pages#terms_of_service', :as => :terms_of_service

  get '/distributor_request' => 'static_pages#new_distributor_request', :as => :distributor_request
  post '/distributor_request' => 'static_pages#create_distributor_request'

  # sessions paths
  get 'log_in/' => 'sessions#new'
  post   'log_in/'   => 'sessions#create'
  delete 'log_out/'  => 'sessions#destroy'

  # product paths (what the client sees) #
  get '/products' => 'products#index', :as => :products
  get '/products/:id' => 'products#show', :as => :product
  post '/products/:id/ask' => 'products#ask', :as => :product_ask

  # tips path (what the client sees) #
  get '/tips&recipes' => "tips#index", :as => :tips
  post '/tips&recipes/:id/new_comment' => "tips#create_comment", :as => :create_tip_comment
  get '/tips&recipes/:id' => "tips#show", :as => :tip

  namespace :admin do
    # admin paths
    get '/' => 'welcome#index', :as => :welcome
    get '/suggestions' => 'welcome#suggestions', :as => :suggestions
    post '/suggestion/:id/send_answer' => 'welcome#answer_suggestion', :as => :answer_suggestion
    #get '/configurations' => 'welcome#configurations', :as => :configurations
    #post '/configurations' => 'welcome#update_configurations'
    get '/notifications' => 'welcome#notifications', :as => :notifications

    # clients #
    get '/clients' => 'clients#index', :as => :clients
    get '/clients/:id' => 'clients#show', :as => :client
    get '/clients/:id/orders' => 'clients#orders', :as => :client_orders
    get '/clients/:id/prices' => 'clients#prices', :as => :client_prices
    get '/clients/:id/revisions' => 'clients#revisions', :as => :client_revisions
    get '/clients/:id/visits' => 'clients#visits', :as => :client_visits

    get 'mexico-db/states' => 'mexico_db#index', :as => :mexico_db
    get 'mexico-db/states/:id' => 'mexico_db#state', :as => :mexico_state
    put 'mexico-db/states/:id' => 'mexico_db#update_state_lada'
    put 'mexico-db/states/cities/:id' => 'mexico_db#update_city', :as => :mexico_city
    post 'mexico-db/states/cities' => 'mexico_db#create_city', :as => :create_city

    resources :banks, except: :show do
      resources :bank_accounts, except: :show, :as => 'accounts'
    end

    resources :site_workers do
      get 'permissions/edit', action: :edit_permissions, on: :member, :as => :edit_permissions
      put 'permissions', action: :update_permissions, on: :member, :as => :update_permissions
    end

    # distributors #
    resources :distributors
    resources :distributor_regions, path: 'distributor/:dist_id/regions', except: [ :edit, :update, :show, :new ]
    get '/distributors/candidates/list' => 'distributors#candidates', :as => :distributor_candidates
    post '/distributors/candidates/update/:id' => 'distributors#update_candidate', :as => :update_candidate

    # distributor_work #
    get 'distributor_work/clients/' => 'distributor_work#index', :as => :distributor_work_clients
    put 'distributor_work/clients/:id/take' => 'distributor_work#take_client', :as => :distributor_work_take_client
    get 'distributor_work/my_clients/' => 'distributor_work#my_clients', :as => :distributor_work_my_clients
    get 'distributor_work/client/:id/prices' => 'distributor_work#prices', :as => :distributor_work_client_prices
    post 'distributor_work/client/:id/prices' => 'distributor_work#create_prices', :as => :distributor_work_client_create_prices
    get 'distributor_work/my_clients/orders' => 'distributor_work#orders', :as => :distributor_work_orders

    get 'distributor_work/client/:id/messages' => 'distributor_work#messages', :as => :distributor_work_client_messages
    post 'distributor_work/client/:id/messages' => 'distributor_work#create_message'

    # products #
    resources :products
    get '/products/:id/photo/:photo_id/update' => "products#set_principal_photo", :as => :products_set_principal
    get '/products/:id/photo/:photo_id/destroy' => "products#destroy_photo", :as => :products_photo_destroy
    resources :product_questions, only: [ :index, :create ]
    get 'product_questions/answered' => 'product_questions#answered', :as => :product_answered_questions

    # warehouses #
    resources :warehouses
    resources :warehouse_regions, path: 'warehouses/:warehouse_id/regions', except: [ :edit, :update, :show, :new ]

    resources :warehouse_products, path: 'warehouses/:warehouse_id/products', only: [ :index ]

    get 'warehouses/batch/search' => 'warehouses#batch_search', :as => :batch_search
    get 'warehouses/:warehouse_id/inventory/impression_format' => 'warehouses#inventory', :as => :inventory

    get 'warehouses/:warehouse_id/products/:id/stock_details' => 'warehouse_products#stock_details', :as => :warehouse_products_stock_details
    put 'warehouses/:warehouse_id/products/:id/stock_details' => 'warehouse_products#update_stock'

    get 'chief/warehouses/:warehouse_id/products' => 'warehouse_products#chief_index', :as => :chief_warehouse_products
    post 'chief/warehouses/:warehouse_id/products/:id/prepare_for_shipment' => 'warehouse_products#prepare_product_for_shipment', :as => :prepare_product_for_shipment
    delete 'chief/warehouses/:warehouse_id/products/preparations/:id' => 'warehouse_products#discard_shipment_preparation', :as => :discard_shipment_preparation
    put 'chief/warehouses/:warehouse_id/products/:id/update_min_stock' => 'warehouse_products#update_min_stock', :as => :update_product_min_stock

    # warehouse parcels #
    get 'warehouses/:id/parcels' => 'parcels#index', :as => :warehouse_parcels
    get 'warehouses/:id/parcels/new' => 'parcels#new', :as => :warehouse_new_parcel
    post 'warehouses/:id/parcels' => 'parcels#create'
    get 'warehouses/:warehouse_id/parcel/:id/edit' => 'parcels#edit', :as => :warehouse_edit_parcel
    put 'warehouses/:warehouse_id/parcel/:id' => 'parcels#update', :as => :warehouse_parcel
    delete 'warehouses/:warehouse_id/parcel/:id' => 'parcels#destroy'

    # shipments #
    get 'chief/warehouses/:warehouse_id/shipments' => 'warehouse_products#chief_shipments', :as => :chief_shipments
    post 'chief/warehouses/:warehouse_id/shipments' => 'warehouse_products#create_shipment'
    get 'chief/warehouses/:warehouse_id/shipment/:id/details' => 'warehouse_products#chief_shipment_details', :as => :chief_shipment_details
    delete 'chief/warehouses/:warehouse_id/shipment/:id' => 'warehouse_products#destroy_shipment', :as => :chief_destroy_shipment

    post 'chief/warehouses/print_qr' => 'warehouse_products#print_qr', :as => :print_qr

    get 'warehouses/:warehouse_id/shipments' => 'warehouse_products#shipments', :as => :shipments
    get 'warehouses/:warehouse_id/shipment/:id/details' => 'warehouse_products#shipment_details', :as => :shipment_details
    post 'warehouses/:warehouse_id/shipment/:id/received_it_complete' => 'warehouse_products#receive_complete_shipment', :as => :receive_complete_shipment

    # shipment difference reports #
    post 'warehouses/:warehouse_id/shipment/:id/add_report_quantity_to_stock' => 'warehouse_products#add_report_quantity_to_stock', :as => :add_report_quantity_to_stock
    post 'warehouses/:warehouse_id/shipment/:id/difference_report' => 'warehouse_products#create_difference_report', :as => :difference_report

    # orders #
    get 'orders/' => 'orders#index', :as => :orders
    put 'order/:id/accept_pay/:accept' => 'orders#accept_pay', :as => :accept_order_pay

    get 'order/:id/details' => 'orders#details', :as => :order_details

    delete 'order/:id' => 'orders#cancel', :as => :cancel_order
    put 'order/:id/inspection' => 'orders#inspection', :as => :inspection_order
    put 'order/:id/supply_error' => 'orders#supply_error', :as => :order_supply_error
    get 'order/:id/capture_details' => 'orders#capture_details', :as => :capture_details
    post 'order/:id/capture_details' => 'orders#save_details'
    put 'order/:id/capture_tracking_code' => 'orders#save_tracking_code', :as => :capture_tracking_code
    put 'order/:id/delivered' => 'orders#save_as_delivered', :as => :order_delivered
    put 'order/:id/invoice' => 'orders#invoice_delivered', :as => :order_invoice_delivered
    get 'order/:payment_key/download_payment_file' => 'orders#download_payment_file', :as => :download_payment

    # orders search #
    get 'orders/search' => 'orders#search', :as => :orders_search
    get 'order/:id/show_activities' => 'orders#show_activities', :as => :show_order_activities

    # download orders info as txt #
    get 'orders/invoice/download' => 'orders#download_invoice_data', :as => :download_orders_invoice_data

    # bank reports
    get 'bank_report/' => 'bank_reports#index', :as => :bank_report
    post 'bank_report/' => 'bank_reports#show'

    # supervisor #
    get "clients/:id/supervisor_visits/" => 'clients#supervisor_visits', :as => :supervisor_visits
    get "clients/:id/supervisor_visits/:visit_id/details" => 'clients#supervisor_visit_details', :as => :supervisor_visit_details
    get "clients/:id/supervisor_visits/new" => 'clients#new_supervisor_visit', :as => :new_supervisor_visit
    post "clients/:id/supervisor_visits/new" => 'clients#create_supervisor_visit'

    # statistics #
    get 'statistics' => 'statistics#index', :as => :statistics
    post 'statistics/sales' => 'statistics#sales', :as => :sales_statistics
    post 'statistics/best_distributors' => 'statistics#best_distributors', :as => :best_dist_statistics
    post 'statistics/best_clients' => 'statistics#best_clients', :as => :best_clients_statistics

    # web #
    get 'web' => 'web#index', :as => :web
    get 'web/video' => 'web#videos', :as => :web_videos
    post 'web/video' => 'web#upload_video'
    delete 'web/video' => 'web#reset_videos'

    get 'web/gallery' => 'web#photos', :as => :web_photos
    post 'web/gallery' => 'web#upload_photos'
    delete 'web/gallery/:id' => 'web#destroy_photo', :as => :web_destroy_photo

    get 'web/offers' => 'web#offers', :as => :web_offers
    post 'web/offers' => 'web#upload_offers'
    delete 'web/offers/:id' => 'web#destroy_offer', :as => :web_destroy_offer

    get 'web/footer_details' => 'web#footer_details', :as => :web_footer_details
    post 'web/footer_details' => 'web#create_footer_detail'
    delete 'web/footer_details/:id' => 'web#delete_footer_detail', :as => :web_footer_detail

    get 'web/info/:name' => 'web#edit_info', :as => :web_info
    put 'web/info/:name' => 'web#update_info'

    get 'web/social_networks' => 'web#social_networks', :as => :web_social_networks
    put 'web/social_networks/:id' => 'web#update_social_networks', :as => :update_social_network

    get 'web/services' => 'web#services', :as => :web_services
    put 'web/services/:id' => 'web#update_services', :as => :web_service

    # tips & recipes #
    resources :tips, :except => [:show, :destroy]

    # commissions #
    get '/commissions' => 'commissions#index', :as => :commissions
    post '/commissions' => 'commissions#create'
    get '/commissions/:id/details' => 'commissions#details', :as => :commission_details
    post '/commissions/:id/upload_payment' => 'commissions#upload_payment', :as => :upload_commission_payment
    get '/commissions/:id/invoice' => 'commissions#download_invoice', :as => :download_commission_invoice
  end

  namespace :distributor do
    # distributor paths
    get '/' => 'admin#index', :as => :welcome
    post '/update_home_image' => 'admin#update_home_image', :as => :update_home_image

    get '/notifications' => 'admin#notifications', :as => :notifications

    get '/clients' => 'clients#index', :as => :clients
    get '/clients/:id' => 'clients#show', :as => :client

    get '/clients/:id/prices' => 'clients#prices', :as => :client_prices
    post '/clients/:id/prices' => 'clients#create_prices', :as => :client_create_prices

    get '/orders' => 'orders#index', :as => :orders
    get '/orders/:id/details' => 'orders#details', :as => :order_details

    get '/client/:id/visits' => 'visits#index', :as => :client_visits
    post 'client/:id/visits' => 'visits#create'

    get '/client/:id/messages' => 'clients#messages', :as => :client_messages
    post '/client/:id/messages' => 'clients#create_message'

    # commissions #
    get '/commissions' => 'commissions#index', :as => :commissions
    get '/commissions/:id/details' => 'commissions#details', :as => :commission_details
    post '/commissions/:id/upload_invoice' => 'commissions#upload_invoice', :as => :upload_commission_invoice
  end

  namespace :client do
    # notifications #
    get 'user/:id/notifications' => 'clients#notifications', :as => :notifications

    # distributor visits #
    put '/user/visits/:id' => 'clients#update_distributor_visit', :as => :update_distributor_visit

    # distributor comments #
    post '/user/distributor/:id/message/create' => 'clients#create_distributor_comment', :as => :create_distributor_comment

    # client paths
    get '/user/:id/destroy_account' => 'clients#pre_destroy_account', :as => :destroy_account
    post '/user/:id/destroy_account' => 'clients#destroy_account'

    get '/my_distributor/' => "clients#distributor", :as => :my_distributor
    get '/user/:id' => "clients#index"
    get 'sign_up' => "clients#new"
    resources :clients, except: [ :new, :index ]
    get 'question/:id' => 'clients#prod_answer', :as => :question_answer

    get "user/:user_id/ecart" => "ecarts#show", :as => :ecart
    put 'products/:id/add_to_cart' => 'ecarts#add_to_cart', :as => :add_to_cart
    put 'user/:user_id/ecart/remove/:product' => "ecarts#remove_from_cart", :as => :remove_from_cart
    put 'user/:user_id/ecart/change_quantity' => "ecarts#update_quantity", :as => :ecart_update_quantity

    get 'user/:user_id/orders/' => "orders#index", :as => :orders
    get 'user/:user_id/orders/:id' => "orders#show", :as => :order
    post 'user/:user_id/orders/' => "orders#create", :as => :create_order
    delete 'user/:user_id/orders/:id' => "orders#cancel", :as => :cancel_order
    put 'user/:user_id/orders/:id' => "orders#upload_payment", :as => :upload_pay_order
    get 'user/:user_id/orders/:id/get_payment' => 'orders#get_payment', :as => :get_order_payment
    get 'user/:user_id/orders/:id/get_bank_payment_info' => 'orders#get_bank_payment_info', :as => :get_bank_payment_info
    patch 'user/:user_id/orders/:id/update_payment_method' => 'orders#update_payment_method', :as => :update_payment_method

    resources :fiscal_data, except: [ :index ]
  end

  namespace :api do
    get 'notifications' => 'users#notifications'
    post 'update_visit' => 'users#update_distributor_visit'

    post 'log_in' => 'sessions#create'
    post 'log_out' => 'sessions#destroy'

    get 'states' => 'locations#states'
    get 'state/:id/cities' => 'locations#cities'

    get 'privacy_policy' => 'information#privacy_policy'
    get 'terms_of_service' => 'information#terms_of_service'
    get 'tips_&_recipes' => 'information#tips'
    get 'ecart_info' => 'information#ecart_info'
    post 'contact' => 'information#contact'

    # client actions #
    post 'fiscal_data' => 'fiscal_data#create'
    post 'fiscal_data/update' => 'fiscal_data#update'
    get 'fiscal_data' => 'fiscal_data#show'

    post 'users' => 'users#create'
    post 'users/update' => 'users#update'
    get 'users' => 'users#show'
    get 'users/get_username_n_photo' => 'users#get_username_n_photo'
    post 'users/destroy' => 'users#destroy'

    get 'products' => 'products#index'
    get 'products/:id' => 'products#show'

    post 'new_distributor_request' => 'distributors#create_candidate'
    get 'my_distributor' => 'distributors#show'
    get 'my_distributor/messages' => 'distributors#messages'
    post 'my_distributor/messages' => 'distributors#create_message'

    get 'my_orders' => 'orders#index'
    get 'my_orders/:id' => 'orders#show'
    post 'my_orders' => 'orders#create'
    post 'my_orders/:id/payment' => 'orders#upload_payment'
    post 'my_orders/:id/cancel' => 'orders#cancel'
    get 'orders/payment_steps' => 'orders#payment_steps'

    namespace :distributor_api do
      get "index" => "distributors#index"
      get "notifications" => "distributors#notifications"
      get "get_username_n_photo" => "distributors#get_username_n_photo"
      post "update_home_image" => "distributors#update_home_image"

      get "clients" => "clients#index"
      get "client/:id" => "clients#show"
      get "client/:id/prices" => "prices#index"
      post "client/:id/prices" => "prices#update"
      get "client/:id/messages" => "messages#index"
      post "client/:id/messages" => "messages#create"

      get "client/:id/visits" => "visits#index"
      post "client/:id/visits/new" => "visits#create"

      get "orders" => "orders#index"
      get "order/:id" => "orders#show"

      get "commissions" => "commissions#index"
      get "commission/:id" => "commissions#show"
    end

    namespace :workers_api do
      get "order/:id/client" => "clients#show"
      get "order/:id/distributor" => "distributors#show"
      get "warehouse_products" => "warehouse_products#index"

      get "orders/count" => "orders#count"
      get "orders" => "orders#index"
      get "order/:id" => "orders#show"
      post "order/:id/capture_batches" => "orders#save_details"

      get "orders/supplied" => "orders#supplied"
    end
  end

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
