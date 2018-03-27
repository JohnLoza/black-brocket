class TipRecipe < ApplicationRecord
  include Searchable
  attr_accessor :body
  has_many :Comments, class_name: :TipRecipeComment, foreign_key: :tip_recipe_id

  mount_uploader :image, ImageUploader
  mount_uploader :video, VideoUploader

  validates :description_render_path, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def latestComments(quantity = 10)
    self.Comments.order(created_at: :desc).limit(quantity)
  end
end
