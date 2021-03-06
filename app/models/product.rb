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
  scope :visible, -> { where(show: true) }
  scope :order_by_name, -> (way = :asc) {
    order(name: way)
  }

  def self.by_category(category)
    return all unless category.present? and ["hot","cold","frappe"].include? category
    where("#{category}" => true)
  end

  def self.priceFor(product, custom_prices, offers = WebOffer.getSpecialOffers)
    price = 0
    if custom_prices.kind_of? ClientProduct
      custom_prices = [custom_prices] if custom_prices
    end

    if custom_prices and custom_prices.size > 0
      custom_prices.each do |cp|
        price = cp.client_price if cp.product_id == product.product_id
      end
    end
    
    price = product.Product.price if price == 0
    if offers
      offer = WebOffer.specialOfferFor(product.product_id, offers)
      if offer
        price = price * (100 - offer["discount"]) / 100
      end
    end

    return price
  end

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
