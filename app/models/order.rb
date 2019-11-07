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

  def json_guides
    begin
      JSON.parse self.guides
    rescue => exception
      nil
    end
  end

  def cancel!(message = nil)
    details = OrderDetail.where(order_id: self.id)

    ActiveRecord::Base.transaction do
      details.each {|d| WarehouseProduct.return(d.w_product_id, d.quantity)}

      self.state = "ORDER_CANCELED"
      self.cancel_description = message if message

      self.save!
    end
  end

  def payment_method_code
    case self.payment_method
    when 0
      "OXXO_PAY"
    when -1
      "BBVA"
    else
      "BANK_DEPOSIT"
    end
  end

  def create_conekta_charge(current_user, products, custom_prices)
    require "conekta"
    Conekta.api_key = Order.conekta_api_key()
    Conekta.api_version = "2.0.0"

    line_items = fill_line_items(self, products, custom_prices)

    shipping_lines = [{
      amount: self.json_guides["shipping_cost"] * 100,
      carrier: self.json_guides["provider"]
    }]

    conekta_order = Conekta::Order.create({
      line_items: line_items,
      shipping_lines: shipping_lines,
      currency: "MXN",
      customer_info: current_user.conekta_customer_info,
      shipping_contact: current_user.conekta_shipping_contact,
      charges: [{
        payment_method: { type: "oxxo_cash" }
      }]
    })

    self.update_attributes!(conekta_order_id: conekta_order.id)
  end

  def self.conekta_api_key()
    Rails.env == "production" ? "key_ijaE3XbzbzhjdaYmrzKWMg" : "key_H4tGgYkAV9sG8zpLw6sUzA"
  end

  def create_bbva_charge(client, order)
    bbva = self.bbva_instance()
    charges = bbva.create(:charges)

    charge_params = {
      "affiliation_bbva" => "582762",
      "amount" => order.total,
      "currency" => "MXN",
      "description" => "Compra de productos Black Brocket",
      "order_id" => order.hash_id,
      "redirect_url" => Rails.application.routes.url_helpers.bbva_callback_url(order.hash_id),
      "customer" => client.bbva_customer_info
    }

    response = charges.create(charge_params)
    return response
  end

  def bbva_instance
    require 'bbva'
    merchant_id = Rails.env == "production" ? 'muk6sqpsrrax6rkee078' : 'mx316pz06s7aq7svcyrg'
    if Rails.env == "production"
      private_key = 'sk_83944fb5358a49cabd2d6a762bbccadb'
    else
      private_key = 'sk_365b9b836b624816ae433004589c8bff'
    end
    is_production = Rails.env == "production"

    BbvaApi.new(merchant_id, private_key, is_production)
  end

  private
    def generate_hash_id
      loop do
        self.hash_id = Utils.new_alphanumeric_token(9).upcase unless self.hash_id.present?
        break unless hash_id_taken?(self.hash_id)
      end
    end

    def fill_line_items(order, warehouse_products, custom_prices)
      line_items = Array.new
      order.Details.each do |order_detail|
        wp = warehouse_products.find{ |wp| wp.product_id == order_detail.product_id }
        product = wp.Product
        price = Product.priceFor(wp, custom_prices)
        line_items << {
          name: product.name,
          unit_price: (price * 100).to_i,
          quantity: order_detail.quantity
        }
      end

      return line_items
    end
end
