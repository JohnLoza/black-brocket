class SupervisorVisitDetail < ActiveRecord::Base
  belongs_to :Visit, :class_name => :SupervisorVisit, :foreign_key => :visit_id
end
