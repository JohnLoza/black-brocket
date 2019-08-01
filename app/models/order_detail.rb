class OrderDetail < ApplicationRecord
  belongs_to :Order, foreign_key: :order_id, optional: true
  belongs_to :Product, foreign_key: :product_id, optional: true

  validates :product_id, :quantity, :w_product_id,
    presence: true, numericality: { only_integer: true }
  validates :sub_total, :iva, :ieps, :total_iva, :total_ieps, 
    presence: true, numericality: true

  def self.for(custom_prices, product, info)
    subtotal = 0
    current_product_price = Product.priceFor(product, custom_prices)
    subtotal = info[product.hash_id].to_i * current_product_price
    total_iva = current_product_price-(current_product_price*100/(product.Product.iva+100))
    total_ieps = (current_product_price-total_iva)-((current_product_price-total_iva)*100/(product.Product.ieps+100))

    return OrderDetail.new(product_id: product.product_id, price: current_product_price,
      hash_id: Utils.new_alphanumeric_token(9).upcase, iva: product.Product.iva,
      quantity: info[product.hash_id], sub_total: subtotal,
      w_product_id: product.id, ieps: product.Product.ieps, 
      total_iva: total_iva * info[product.hash_id].to_i,
      total_ieps: total_ieps * info[product.hash_id].to_i)
  end

  def self.required_products_hash(order_id)
    order_details = OrderDetail.select(:product_id, :quantity).where(order_id: order_id)
    raise ActiveRecord::RecordNotFound unless order_details.size > 0

    details_hash = Hash.new
    order_details.each do |detail|
      key = detail.product_id.to_s
      details_hash[key] = Hash.new
      details_hash[key][:products_required_by_the_user] = detail.quantity
      details_hash[key][:quantity_captured] = 0
    end
    return details_hash
  end
end
