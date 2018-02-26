class DistributorVisit < ApplicationRecord
  belongs_to :Distributor, :foreign_key => :distributor_id
  belongs_to :Client, :foreign_key => :client_id
end
