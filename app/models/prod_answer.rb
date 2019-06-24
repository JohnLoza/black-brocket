class ProdAnswer < ApplicationRecord
  belongs_to :Question, class_name: "ProdQuestion", foreign_key: :question_id
  belongs_to :SiteWorker, foreign_key: :site_worker_id

  validates :question_id, :site_worker_id, presence: true, numericality: { only_integer: true }

  validates :description, presence: true
end
