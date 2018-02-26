class Permission < ApplicationRecord
  belongs_to :Worker, :class_name => 'SiteWorker', :foreign_key => :worker_id
end
