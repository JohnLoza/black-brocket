class Order < ApplicationRecord
  include HashId
  
  belongs_to :City, foreign_key: :city_id, optional: true
  belongs_to :Distributor, foreign_key: :distributor_id, optional: true
  belongs_to :Client, foreign_key: :client_id, optional: true
  belongs_to :Warehouse, foreign_key: :warehouse_id, optional: true
  has_many :Details, class_name: :OrderDetail, foreign_key: :order_id
  has_many :Actions, class_name: :OrderAction, foreign_key: :order_id

  validates :client_id, :city_id, :distributor_id,
  :total, presence: true, on: :create

  validates :client_id, :distributor_id,
  numericality: { only_integer: true }, on: :create

  validates :total, numericality: true, on: :create

  mount_uploader :payment, PaymentUploader

  def self.byWarehouse(warehouse)
    return all unless warehouse
    raise ArgumentError, "warehouse must be an integer" unless warehouse.kind_of? Integer

    where(warehouse_id: warehouse)
  end

  def address_hash
    eval self.address
  end
  
  def address_for_google
    hash = address_hash
    str = "#{hash[:street]}+#{hash[:extnumber]}"
    str += "+interior+#{hash[:intnumber]}" if hash[:intnumber].present?
    str += "+#{hash[:col]}+#{hash[:cp]}"
    return str
  end

  def self.by_statements(statements, distributor_id)
    if distributor_id.present?
      distributor = Distributor.find_by!(hash_id: distributor_id)

      Order.joins(:Distributor)
        .where(distributors: {hash_id: distributor_id})
        .where(statements[:where])
        .byWarehouse(statements[:warehouse])
        .order(statements[:order])
        .includes(City: :State).includes(:Distributor, :Client)
    else
      Order.where(statements[:where])
        .byWarehouse(statements[:warehouse])
        .order(statements[:order])
        .includes(City: :State).includes(:Distributor, :Client)
    end
  end

  private
    def generate_hash_id
      loop do
        self.hash_id = Utils.new_alphanumeric_token(9).upcase unless self.hash_id.present?
        break unless hash_id_taken?(self.hash_id)
      end
    end
end
