class SocialNetwork < ApplicationRecord
  validates :url, presence: true
end
