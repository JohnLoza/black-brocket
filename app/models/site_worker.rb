class SiteWorker < ApplicationRecord
  include Rails.application.routes.url_helpers
  include HashId
  include Searchable
  include SoftDeletable
  include User
  attr_accessor :remember_token, :loaded_permissions

  before_save { self.email = email.downcase }
  has_secure_password

  has_many :ProdAnsweres
  belongs_to :City, :foreign_key => :city_id
  belongs_to :Warehouse, :foreign_key => :warehouse_id
  has_many :Permissions, :class_name => 'Permission', :foreign_key => :worker_id
  has_many :Clients, :class_name => :Client, :foreign_key => :worker_id

  has_many :ClientMessages, :class_name => :ClientDistributorComment, :foreign_key => :worker_id
  has_many :Notifications, :class_name => :Notification, :foreign_key => :worker_id

  validates :city_id, presence: true,
                      numericality: { only_integer: true }

  validates :password, length: { minimum: 6 }, :on => :create

  validates :name, :email, :username,
            :rfc, :nss, :address, :telephone, presence: true

  validates :rfc, :nss, uniqueness: {case_sensitive: false }

  validates :email, uniqueness: { case_sensitive: false }
  validates :email, :confirmation => true

  validates :name, :lastname, :mother_lastname,
        format: { with: /\A[a-zA-ZÑñáéíóúü\s\.']+\z/ }

  mount_uploader :photo, AvatarUploader

  scope :admin, -> { where(is_admin: true) }
  scope :non_admin, -> { where(is_admin: false) }
  scope :not, ->  (id) { where.not(id: id)}

  scope :recent, ->    { order(created_at: :desc) }
  scope :order_by_name, -> (way = nil) {
    way = :asc unless way.present?
    order(name: way)
  }

  # Returns if the user has or not at least one of the given roles
  # The splat (*) will automatically convert all arguments into an Array
  def has_permission?(required_permission)
    return true if self.is_admin
    load_permissions unless self.loaded_permissions.present?

    if self.loaded_permissions.include?(required_permission.upcase)
      return true
    else
      return false
    end
  end

  # Returns if the user has or not all the given roles
  def has_permissions?(*required_permissions)
    return true if self.is_admin
    load_permissions unless self.loaded_permissions.present?

    required_permissions.each do |r|
      return false unless self.loaded_permissions.include?(r.upcase)
    end
    return true
  end

  def has_permission_category?(permission_category)
    return true if self.is_admin
    load_permissions unless self.loaded_permissions.present?

    self.loaded_permissions.grep(/^#{permission_category.upcase}@/).any?
  end

  def load_permissions
    self.loaded_permissions = Array.new
    self.Permissions.each do |per|
      self.loaded_permissions << "#{per.category}@#{per.name}"
    end
  end

end
