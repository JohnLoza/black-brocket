class State < ActiveRecord::Base
  belongs_to :Country, :foreign_key => :country_id
  belongs_to :Warehouse, :foreign_key => :warehouse_id
  has_many :Cities, :foreign_key => :state_id

  validates :country_id, presence: true, numericality: { only_integer: true }
  validates :name, presence: true
end
