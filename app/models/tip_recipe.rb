class TipRecipe < ApplicationRecord
  include Searchable
  attr_accessor :body
  has_many :Comments, class_name: :TipRecipeComment, foreign_key: :tip_recipe_id

  before_save :get_embed_link

  mount_uploader :image, ImageUploader

  validates :description_render_path, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def latestComments(quantity = 10)
    self.Comments.order(created_at: :desc).limit(quantity)
  end

  private
    def get_embed_link
      return unless self.video.present?
      return unless self.video.include? "youtube.com"
      return if self.video.include? "/embed/"

      video_key = self.video.scan(/v=.........../) # get the video key
      video_key = video_key[0].remove "v=" # remove the "v" attribute

      self.video = "https://www.youtube.com/embed/#{video_key}"
    end
end
