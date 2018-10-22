class Notification < ApplicationRecord
  belongs_to :Client, class_name: :Client, foreign_key: :client_id, optional: true
  belongs_to :Distributor, class_name: :Distributor, foreign_key: :distributor_id, optional: true
  belongs_to :Worker, class_name: :SiteWorker, foreign_key: :worker_id, optional: true

  validates :url, :icon, :description, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
