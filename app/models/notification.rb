class Notification < ApplicationRecord
  belongs_to :Client, :foreign_key => :client_id
  belongs_to :Distributor, :foreign_key => :distributor_id

  validates :url, :icon, :description, presence: true
end
