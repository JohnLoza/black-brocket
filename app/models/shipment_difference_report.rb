class ShipmentDifferenceReport < ActiveRecord::Base
  has_many :Details, class_name: 'ShipmentDifferenceReportDetail', :foreign_key => 'difference_report_id'
end
