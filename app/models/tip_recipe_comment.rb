class TipRecipeComment < ApplicationRecord
  belongs_to :Client, foreign_key: :client_id

  validates :tip_recipe_id, :client_id, :description, presence: true, on: :create
end
