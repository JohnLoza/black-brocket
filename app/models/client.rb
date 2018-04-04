class Client < ApplicationRecord
  include HashId
  include Searchable
  include SoftDeletable
  include User
  attr_accessor :remember_token

  before_save { self.email = email.downcase }
  has_secure_password

  belongs_to :City, foreign_key: :city_id
  belongs_to :Worker, class_name: :SiteWorker, foreign_key: :worker_id
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

  validates :password, length: { minimum: 6 }, :on => :create

  validates :email, :username, :street, :street_ref1, :street_ref2,
            :cp, :col, :extnumber, presence: true

  validates :email, uniqueness: { case_sensitive: false }, :on => :create
  validates :email, :confirmation => true
  validates :email_confirmation, :presence =>true, :on => :create

  validates :name, :lastname, :mother_lastname,
        format: { with: /\A[a-zA-ZÑñáéíóúü\s\.']+\z/ }

  mount_uploader :photo, AvatarUploader

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

end
