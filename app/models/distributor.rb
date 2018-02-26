class Distributor < ApplicationRecord
  attr_accessor :remember_token

  before_save { self.email = email.downcase }
  has_secure_password

  belongs_to :City, :foreign_key => :city_id
  has_many :Orders
  has_many :Regions, :class_name => 'City', :foreign_key => :distributor_id

  has_many :DistributorVisits
  has_many :ClientMessages, :class_name => :ClientDistributorComment, :foreign_key => :distributor_id
  has_many :Notifications, :class_name => :Notification, :foreign_key => :distributor_id
  has_many :Commissions, :class_name => :Commission, :foreign_key => :distributor_id

  validates :city_id, numericality: { only_integer: true }

  validates :password, length: { minimum: 6 }, :on => :create

  validates :city_id, :name, :email, :username, :fiscal_number,
            :rfc, :address, :telephone, presence: true

  validates :email, :rfc, uniqueness: { case_sensitive: false }
  validates :email, :confirmation => true

  validates :name, :lastname, :mother_lastname,
        format: { with: /\A[a-zA-ZÑñáéíóúü\s\.']+\z/ }

  mount_uploader :photo, AvatarUploader
  mount_uploader :home_img, ImageUploader

  def getHomeImage(default = nil)
    image = ""
    if !self.home_img.blank?
      image = self.home_img.url
    else
      image = default
    end # if !self.photo.blank? #
  end

  # When have search params
  def self.search(search, params_page)
    page = params_page
    page = 1 if !page

    if search.at(",") == ","
      search=search.gsub(/\s+/, "")
      search=search.gsub(',','|')
      operator = "REGEXP"
    else
      search = "%"+search+"%"
      operator = "LIKE"
    end

    joins(City: :State).where("
      distributors.deleted=false and
      (cities.name #{operator} :search or
      states.name #{operator} :search or
      distributors.name #{operator} :search or
      distributors.lastname #{operator} :search or
      distributors.mother_lastname #{operator} :search or
      distributors.hash_id #{operator} :search)", search: search).order(created_at: :DESC).paginate(:page =>  page, :per_page => 20).includes(City: :State)
  end

  def self.show_admin(params_page)
    page = params_page
    page = 1 if !page

    where(deleted: false).order(created_at: :DESC).paginate(:page =>  page, :per_page => 20).includes(City: :State)
  end

  def getName()
    return self.name + " " + self.lastname + " " + self.mother_lastname
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
end
