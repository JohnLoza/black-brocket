class SiteWorker < ApplicationRecord
  include Rails.application.routes.url_helpers
  include Searchable
  attr_accessor :remember_token

  before_save { self.email = email.downcase }
  has_secure_password

  has_many :ProdAnsweres
  belongs_to :City, :foreign_key => :city_id
  belongs_to :Warehouse, :foreign_key => :warehouse_id
  has_many :Permissions, :class_name => 'Permission', :foreign_key => :worker_id
  has_many :Clients, :class_name => :Client, :foreign_key => :worker_id

  has_many :ClientMessages, :class_name => :ClientDistributorComment, :foreign_key => :worker_id
  has_many :Notifications, :class_name => :Notification, :foreign_key => :worker_id

  validates :city_id, presence: true,
                      numericality: { only_integer: true }

  validates :password, length: { minimum: 6 }, :on => :create

  validates :name, :email, :username,
            :rfc, :nss, :address, :telephone, presence: true

  validates :rfc, :nss, uniqueness: {case_sensitive: false }

  validates :email, uniqueness: { case_sensitive: false }
  validates :email, :confirmation => true

  validates :name, :lastname, :mother_lastname,
        format: { with: /\A[a-zA-ZÑñáéíóúü\s\.']+\z/ }

  mount_uploader :photo, AvatarUploader

  # When have search params
  def self.search(search, params_page, current_user_id)
    page = params_page
    page = 1 if !page

    if search.at(",") == ","
      search=search.gsub(/\s+/, "")
      search=search.gsub(',','|')
      operator = "REGEXP"
    else
      search = "%"+search+"%"
      operator = "LIKE"
    end

    joins(City: :State).where("site_workers.is_admin=false and
      site_workers.deleted=false and
      (cities.name #{operator} :search or
      states.name #{operator} :search or
      site_workers.name #{operator} :search or
      site_workers.lastname #{operator} :search or
      site_workers.mother_lastname #{operator} :search or
      site_workers.hash_id #{operator} :search) and
      site_workers.id <> #{current_user_id}", search: search).order(created_at: :DESC).paginate(:page =>  page, :per_page => 20).includes(City: :State)
  end

  def self.getWorkers(params_page, current_user_id, warehouse = nil)
    page = params_page
    page = 1 if !page

    where_stat = "is_admin = false and deleted = false and id <> #{current_user_id}"
    where_stat += " and warehouse_id = #{warehouse}" if !warehouse.nil?
    where(where_stat).order(created_at: :DESC).paginate(:page =>  page, :per_page => 20).includes(City: :State)
  end

  # check if the user is authorized to continue #
  def is_authorized?(permission_category = nil, permission_names = nil, does_need_permission = true)
    @user_permissions = self.Permissions

    if does_need_permission
      if self.is_admin
        return [get_navbar_links(nil, self.is_admin)]
      end

      continue = false

      # En caso de conseguir solo un nombre de permiso válido transformamos ese string en un array con un elemento #
      permission_names = [permission_names] if !permission_names.kind_of?(Array)

      @user_permissions.each do |p|
        # if we have permission to continue, stop searching #
        break if continue

        if p.category == permission_category
          if permission_names.any?
            permission_names.each do |permission_name|
              if p.name == permission_name
                continue = true
                break
              end # if p.category == permission_category and p.name == permission_names end #
            end # permission_names.each end #
          elsif !permission_category.nil?
            continue = true
          end # if !permission_names.nil? #
        end # if p.category == permission_category #

      end # @user_permissions.each do end #

      if continue
        return [get_navbar_links(@user_permissions, self.is_admin), @user_permissions]
      else
        puts "--- doesn't have enough permissions ---"
        return []
      end # if continue #

    else
      puts "--- doesn't need permission ---"
      return [get_navbar_links(@user_permissions, self.is_admin), @user_permissions]
    end # if does_need_permission #
  end # def is_authorized? #

  # get the correspondent navbar links according to the user permissions #
  def get_navbar_links(user_permissions, get_all = false)
    links = []
    if get_all
      return links = available_links().values
    else
      links = {}
      categories_done = []
      category_list = get_categories

      user_permissions.each do |p|
        link_is_done = false
        categories_done.each do |c|
          if p.category == c or
            (c=="WAREHOUSES" and ["WAREHOUSE_MANAGER","WAREHOUSE_PRODUCTS",
                                 "PARCELS"].include? p.category)
            link_is_done = true
          end
        end # categories_done.each end #

        if !link_is_done
          if category_list.include?(p.category)
            links["#{p.category}"] = available_links(p.category)
            categories_done << p.category
          elsif ["WAREHOUSE_MANAGER", "WAREHOUSE_PRODUCTS", "PARCELS"].include?(p.category)
            links["WAREHOUSES"] = available_links("WAREHOUSES")
            categories_done << "WAREHOUSES"
          end # if category_list.include?(p.category) #
        end # if !link_is_done #

      end # user_permissions.each end #
    end # if get_all end #

    return sort_links(links)
  end # def get_navbar_links #

  private
    # get an array of the categories to work with exept for #
    def get_categories
      categories = ["WORKERS","DISTRIBUTORS","DISTRIBUTOR_WORK","PRODUCTS",
                    "WAREHOUSES","ORDERS","PRODUCT_QUESTIONS","STATISTICS",
                    "WEB","CLIENTS","COMMENTS_AND_SUGGESTIONS","BANK_ACCOUNTS",
                    "MEXICO_DB", "TIPS_&_RECIPES", "COMMISSIONS"]
      return categories
    end

    # List of all links available to put on navbar with their correspondent #
    # category needed in permissions to see that link on screen #
    def available_links(link_category = nil)
      links = {"WORKERS"=>{link: admin_workers_path, icon: "fa fa-users", label: "Trabajadores"},
              "DISTRIBUTORS"=>{link: admin_distributors_path, icon: "fa fa-street-view", label: "Distribuidores"},
              "COMMISSIONS"=>{link: admin_commissions_path, icon: "fa fa-money", label: "Comisiones"},
              "DISTRIBUTOR_WORK"=>{link: admin_distributor_work_clients_path, icon: "fa fa-male", label: "Clientes sin distribuidor"},
              "PRODUCTS"=>{link: admin_products_path, icon: "fa fa-cube", label: "Productos"},
              "WAREHOUSES"=>{link: admin_warehouses_path, icon: "fa fa-cubes", label: "Almacenes"},
              "ORDERS"=>{link: admin_orders_path, icon: "fa fa-truck", label: "Órdenes"},
              "PRODUCT_QUESTIONS"=>{link: admin_product_questions_path, icon: "fa fa-question-circle", label: "Preguntas de prod."},
              "STATISTICS"=>{link: admin_statistics_path, icon: "fa fa-area-chart", label: "Estadísticas"},
              "WEB"=>{link: admin_web_path, icon: "fa fa-desktop", label: "Contenido del Sitio"},
              "CLIENTS"=>{link: admin_clients_path, icon: "fa fa-users", label: "Clientes"},
              "COMMENTS_AND_SUGGESTIONS"=>{link: admin_suggestions_path, icon: "fa fa-comments", label: "Comentarios y sugerencias"},
              "BANK_ACCOUNTS"=>{link: admin_banks_path, icon: "fa fa-bank", label: "Cuentas Bancarias"},
              "MEXICO_DB"=>{link: admin_mexico_db_path, icon: "fa fa-map-marker", label: "Entidades de México"},
              "TIPS_&_RECIPES"=>{link: admin_tips_path, icon: "fa fa-book", label: "Tips y Recetas"}}

      if link_category != nil
        return links[link_category]
      else
        return links
      end
    end # def available_links #

    # Sort the links to match the exact structure it has on the available_links method #
    def sort_links(links_hash)
      array = []
      array << available_links["WORKERS"] if !links_hash["WORKERS"].nil?
      array << available_links["DISTRIBUTORS"] if !links_hash["DISTRIBUTORS"].nil?
      array << available_links["COMMISSIONS"] if !links_hash["COMMISSIONS"].nil?
      array << available_links["DISTRIBUTOR_WORK"] if !links_hash["DISTRIBUTOR_WORK"].nil?
      array << available_links["PRODUCTS"] if !links_hash["PRODUCTS"].nil?
      array << available_links["WAREHOUSES"] if !links_hash["WAREHOUSES"].nil?
      array << available_links["ORDERS"] if !links_hash["ORDERS"].nil?
      array << available_links["PRODUCT_QUESTIONS"] if !links_hash["PRODUCT_QUESTIONS"].nil?
      array << available_links["STATISTICS"] if !links_hash["STATISTICS"].nil?
      array << available_links["WEB"] if !links_hash["WEB"].nil?
      array << available_links["CLIENTS"] if !links_hash["CLIENTS"].nil?
      array << available_links["COMMENTS_AND_SUGGESTIONS"] if !links_hash["COMMENTS_AND_SUGGESTIONS"].nil?
      array << available_links["BANK_ACCOUNTS"] if !links_hash["BANK_ACCOUNTS"].nil?
      array << available_links["MEXICO_DB"] if !links_hash["MEXICO_DB"].nil?
      array << available_links["TIPS_&_RECIPES"] if !links_hash["TIPS_&_RECIPES"].nil?

      #puts "--- #{links_hash} ---"
      return array
    end

end
