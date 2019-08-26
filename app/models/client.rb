class Client < ApplicationRecord
  include HashId
  include Searchable
  include SoftDeletable
  include User
  attr_accessor :remember_token

  before_save { self.email = email.downcase }
  before_create { self.validate_email_digest = self.new_token }
  has_secure_password

  belongs_to :City, foreign_key: :city_id
  belongs_to :Worker, class_name: :SiteWorker, foreign_key: :worker_id, optional: true
  has_many :ProductPrices, class_name: :ClientProduct, foreign_key: :client_id
  has_many :Orders
  has_many :ProdQuestions
  has_many :Notifications
  has_many :DistributorRevisions, class_name: :DistributorClientRevision, foreign_key: :client_id
  has_one :FiscalData

  has_many :DistributorVisits
  has_many :SupervisorVisits
  has_many :DistributorMessages, class_name: :ClientDistributorComment, foreign_key: :client_id

  validates :city_id, presence: true, numericality: { only_integer: true }

  validates :password, length: { minimum: 6 }, on: :create

  validates :name, :email, presence: true

  # validates :street, :street_ref1, :street_ref2, :cp, :col, :extnumber, presence: true, on: :update

  validates :email, uniqueness: { case_sensitive: false }, on: :create
  # validates :email, confirmation: true
  # validates :email_confirmation, presence: true, on: :create

  # validates :name, format: { with: /\A[a-zA-ZÑñáéíóúÁÉÍÓÚàèìòùÀÈÌÒÙ\s\.']+\z/ }

  mount_uploader :photo, AvatarUploader

  scope :recent, ->    { order(created_at: :desc) }
  scope :order_by_name, -> (way = :asc) {
    order(name: way)
  }

  def self.byRegion(region_ids)
    return all unless region_ids.present?
    raise ArgumentError, "region_ids should be an array" unless region_ids.kind_of? Array

    where(city_id: region_ids)
  end

  def getAddress()
    city = self.City
    state_name = State.find(city.state_id).name

    address = ""
    address += self.street
    address += " #" + self.extnumber
    if !self.intnumber.blank?
      address += " número int " + self.intnumber
    end
    address += ", colonia " + self.col
    address += ", código postal " + self.cp
    address += ", " + city.name
    address += ", " + state_name

    return address
  end

  def Distributor
    self.City.Distributor
  end

  def distributorId
    dist = self.Distributor
    return dist ? dist.id : 0
  end

  def generate_hash_id
    self.hash_id = "to_be_replaced"
  end

  def set_last_visit(visit)
    return unless visit.client_recognizes_visit
    update_attribute(:last_distributor_visit, visit.visit_date)
  end

  def conekta_customer_info
    {
      name: self.name,
      email: self.email,
      phone: self.cellphone || self.telephone
    }
  end

  def conekta_shipping_contact
    {
      address: {
        street1: "#{self.street_ref1} #{self.extnumber}",
        postal_code: self.cp,
        country: "MX"
      }
    }
  end

  def bbva_customer_info
    {
      "name" => self.name,
      "last_name" => "",
      "phone_number" => self.cellphone || self.telephone,
      "email" => self.email
    }
  end

end
