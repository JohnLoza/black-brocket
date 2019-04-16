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
end
