class Product < ApplicationRecord
  include HashId
  include Searchable
  include SoftDeletable
  attr_accessor :description, :preparation

  before_save :get_embed_link

  has_many :Questions, class_name: 'ProdQuestion', foreign_key: 'product_id'
  has_many :Recipes
  has_many :SubCategories, class_name: 'ProdSubCategory', foreign_key: 'product_id'
  has_many :OrderDetails
  has_many :Photos, class_name: 'ProdPhoto', foreign_key: 'product_id'

  validates :name, :price, presence: true

  validates :price, numericality: {greater_than_or_equal_to: :recommended_price}
  validates :recommended_price, numericality: {greater_than_or_equal_to: :lowest_price}
  validates :lowest_price, numericality: {less_than_or_equal_to: :recommended_price}

  scope :recent, -> { order(created_at: :desc) }
  scope :order_by_name, -> (way = :asc) {
    order(name: way)
  }

  private
    def get_embed_link
      return unless self.video.present?
      return unless self.video.include? 'youtube.com'
      return if self.video.include? '/embed/'

      video_key = self.video.scan(/v=.........../) # get the video key
      video_key = video_key[0].remove 'v=' # remove the 'v' attribute

      self.video = "https://www.youtube.com/embed/#{video_key}"
    end
end
