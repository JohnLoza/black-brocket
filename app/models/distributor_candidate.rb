class DistributorCandidate < ApplicationRecord
  belongs_to :City, class_name: :City, foreign_key: :city_id

  validates :name, :lastname, :city_id, :email, presence: true
  validates :name, :lastname, :mother_lastname,
        format: { with: /\A[a-zA-ZÑñáéíóúü\s\.']+\z/ }

  def getFullName
    return self.name + " " + self.lastname + " " + self.mother_lastname
  end

  def getLocation
    city = self.City
    location = city.name + ", " + city.State.name
    return location
  end
end
