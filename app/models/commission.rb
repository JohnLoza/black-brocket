class Commission < ApplicationRecord
  include Searchable
  belongs_to :Distributor, class_name: :Distributor, foreign_key: :distributor_id
  has_many :Details, class_name: :CommissionDetail, foreign_key: :commission_id

  mount_uploader :payment_img, PayUploader
  mount_uploader :payment_pdf, PdfUploader

  mount_uploader :invoice, CompressedFileUploader

  def self.by_distributor(distributor)
    return all unless distributor.present?
    where(distributor_id: distributor)
  end

  def self.calculateCommission(orders, commission)
    raise ArgumentError, "orders should be present" unless orders
    raise ArgumentError, "commission should be present" unless commission

    total = 0
    orders.each do |o|
      total += o.total
    end
    total = (total * commission) / 100
    return total
  end
end
