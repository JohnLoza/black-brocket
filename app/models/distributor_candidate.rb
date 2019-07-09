class DistributorCandidate < ApplicationRecord
  belongs_to :City, class_name: :City, foreign_key: :city_id

  validates :name, :city_id, :email, presence: true

  def getLocation
    city = self.City
    return "#{city.name}, #{city.State.name}"
  end
end
