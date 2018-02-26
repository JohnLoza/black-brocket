class City < ApplicationRecord
  include Searchable

  belongs_to :State, :foreign_key => :state_id
  belongs_to :Distributor, :foreign_key => :distributor_id
  has_many :Clients, :class_name => 'Client', :foreign_key => :city_id
  has_many :SiteWorkers, :class_name => 'SiteWorker', :foreign_key => :city_id
  has_many :Distributors, :class_name => 'Distributor', :foreign_key => :city_id
  has_many :Orders, :class_name => 'Order', :foreign_key => :city_id
  has_many :Warehouses, :class_name => 'Warehouse', :foreign_key => :city_id

  validates :state_id, :name, presence: true
  validates :state_id, numericality: { only_integer: true }
end
