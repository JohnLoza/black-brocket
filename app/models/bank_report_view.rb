class BankReportView < ApplicationRecord
  belongs_to :Worker, class_name: :SiteWorker, foreign_key: :worker_id
  validates :worker_id, :from_date, :to_date, :details, presence: true
end
