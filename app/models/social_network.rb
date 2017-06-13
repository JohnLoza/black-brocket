class SocialNetwork < ActiveRecord::Base
  validates :url, presence: true
end
