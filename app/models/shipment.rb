class Shipment < ActiveRecord::Base
  belongs_to :OriginWarehouse, class_name: "Warehouse", :foreign_key => :origin_warehouse_id
  belongs_to :TargetWarehouse, class_name: "Warehouse", :foreign_key => :target_warehouse_id

  belongs_to :Worker, class_name: 'SiteWorker', :foreign_key => :worker_id
  belongs_to :Chief, class_name: 'SiteWorker', :foreign_key => :chief_id

  has_many :Details, class_name: 'ShipmentDetail', :foreign_key => 'shipment_id'
  has_one :DifferenceReport, class_name: 'ShipmentDifferenceReport', :foreign_key => 'shipment_id'
end
