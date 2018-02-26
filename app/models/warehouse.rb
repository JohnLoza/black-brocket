class Warehouse < ApplicationRecord
  belongs_to :City, :foreign_key => :city_id
  has_many :Regions, :class_name => 'State', :foreign_key => :warehouse_id
  has_many :Products, :class_name => 'WarehouseProduct', :foreign_key => :warehouse_id

  has_many :TransferShipments, :class_name => 'Shipment', :foreign_key => :origin_warehouse_id
  has_many :IncomingShipments, :class_name => 'Shipment', :foreign_key => :target_warehouse_id

  has_many :Parcels, :class_name => 'Parcel', :foreign_key => :warehouse_id

  validates :city_id, :name, :address, :telephone, presence: true
  validates :city_id, numericality: { only_integer: true }

  # When have search params
  def self.search(search, params_page)
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

    where("(name #{operator} :search or hash_id #{operator} :search) and deleted=false", search: search)
        .order(created_at: :DESC).paginate(:page =>  page, :per_page => 20)
  end

  def self.find_active_ones(params_page)
    page = params_page
    page = 1 if !page

    where(deleted: false).order(created_at: :DESC).paginate(:page =>  page, :per_page => 20)
  end
end
