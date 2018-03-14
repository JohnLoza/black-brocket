class SupervisorVisit < ApplicationRecord
  has_one :Detail, class_name: :SupervisorVisitDetail, foreign_key: :visit_id
  belongs_to :Supervisor, class_name: :SiteWorker, foreign_key: :worker_id
end
