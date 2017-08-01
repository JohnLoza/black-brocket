class BankReportView < ActiveRecord::Base
  validates :worker_id, :from_date, :to_date, :details, presence: true
end
