class Permission < ActiveRecord::Base
  belongs_to :Worker, :class_name => 'SiteWorker', :foreign_key => :worker_id
end
