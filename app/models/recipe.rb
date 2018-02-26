class Recipe < ApplicationRecord
  belongs_to :Product, :foreign_key => :product_id

  validates :product_id, presence: true, numericality: { only_integer: true }

  validates :name, :description, presence: true
end
