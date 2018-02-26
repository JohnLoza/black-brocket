class DistributorRegion < ApplicationRecord
  belongs_to :Distributor, :foreign_key => :distributor_id
  belongs_to :City, :foreign_key => :city_id

  validates :distributor_id, :city_id, presence: true,
                                       numericality: { only_integer: true }
end
