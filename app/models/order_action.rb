class OrderAction < ApplicationRecord
  belongs_to :Worker, class_name: :SiteWorker, foreign_key: :worker_id
  belongs_to :Order, foreign_key: :order_id
end
