class WebOffer < ApplicationRecord
  @@FILE_PATH = "config/black_brocket/special_offers.json"
  validates :url, :photo, presence: true

  mount_uploader :photo, ImageUploader

  def self.setSpecialOffers(json)
    File.write(@@FILE_PATH, json.to_json)
  end
  
  def self.getSpecialOffers
    begin
      JSON.parse File.read(@@FILE_PATH)
    rescue
      nil
    end
  end

  def self.specialOfferFor(product_id, offers = self.getSpecialOffers())
    results = offers.select{|so| so["product_id"] == product_id}
    results.first
  end
end
