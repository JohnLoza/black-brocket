class Country < ActiveRecord::Base
  has_many :States, :class_name => 'State', :foreign_key => :country_id

  validates :name, presence: true
end
