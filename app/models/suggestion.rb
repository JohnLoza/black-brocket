class Suggestion < ApplicationRecord
  scope :unanswered, -> { where(answered: false) }
  scope :answered, ->   { where(answered: true) }
  scope :recent, ->     { order(created_at: :desc) }
  scope :oldest, ->    { order(created_at: :asc) }
end
