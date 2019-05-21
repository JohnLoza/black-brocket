class Suggestion < ApplicationRecord
  validates :name, :email, :message, presence: true
  validates :name, :email, length: { maximum: 50 }
  validates :message, length: { maximum: 250 }

  validates :email, format: { with: /\A.+@.+\z/ }

  scope :unanswered, -> { where(answered: false) }
  scope :answered, ->   { where(answered: true) }
  scope :recent, ->     { order(created_at: :desc) }
  scope :oldest, ->    { order(created_at: :asc) }
end
