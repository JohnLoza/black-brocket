class Distributor < ApplicationRecord
  attr_accessor :remember_token
  include HashId
  include Searchable
  include SoftDeletable
  include User

  before_save { self.email = email.downcase }
  has_secure_password

  belongs_to :City, foreign_key: :city_id
  has_many :Orders
  has_many :Regions, class_name: 'City', foreign_key: :distributor_id

  has_many :DistributorVisits
  has_many :ClientMessages, class_name: :ClientDistributorComment, foreign_key: :distributor_id
  has_many :Notifications, class_name: :Notification, foreign_key: :distributor_id
  has_many :Commissions, class_name: :Commission, foreign_key: :distributor_id

  validates :password, length: { minimum: 6 }, :on => :create

  validates :city_id, :name, :email, :username, :fiscal_number,
            :rfc, :address, :telephone, presence: true

  validates :email, :rfc, uniqueness: { case_sensitive: false }
  validates :email, :confirmation => true

  validates :name, :lastname, :mother_lastname,
        format: { with: /\A[a-zA-ZÑñáéíóúÁÉÍÓÚàèìòùÀÈÌÒÙü\s\.']+\z/ }

  validates :commission, presence: true, numericality: true

  mount_uploader :photo, AvatarUploader
  mount_uploader :home_img, ImageUploader

  scope :recent, ->    { order(created_at: :desc) }
  scope :order_by_name, -> (way = :asc) {
    order(name: way)
  }
  scope :by_region, -> (options = {}) {
    return all unless options[:state_id].present? or options[:city_id].present?
    # give preference to city rather than state search
    if options[:city_id].present?
      # search the distributor by city
      city = City.find_by(id: options[:city_id])
      return all unless city
      where(id: city.distributor_id)
    else # options[:state_id] given
      # search the distributor by state
      cities = City.where(state_id: options[:state_id])
      return all unless cities.any?
      where(id: cities.map(&:distributor_id).uniq)
    end
  }

  def getHomeImage(default = nil)
    image = ""
    if !self.home_img.blank?
      image = self.home_img.url
    else
      image = default
    end # if !self.photo.blank? #
  end

  # update revisions from distributor to client creating timestamps #
  def updateRevision(client)
    last_revision = DistributorClientRevision.where(distributor_id: self.id,
                    client_id: client.id).order(:created_at => :desc).take

    if last_revision
      if last_revision.created_at < 12.hours.ago
        client.update_attribute(:last_distributor_revision, Time.now)
        DistributorClientRevision.create(distributor_id: self.id, client_id: client.id)
      end
    else
      client.update_attribute(:last_distributor_revision, Time.now)
      DistributorClientRevision.create(distributor_id: self.id, client_id: client.id)
    end
  end

  private
    def generate_hash_id
      self.hash_id = 'to_be_replaced'
    end
end
