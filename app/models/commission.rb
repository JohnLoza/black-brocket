class Commission < ActiveRecord::Base
  belongs_to :Distributor, :class_name => :Distributor, :foreign_key => :distributor_id
  has_many :Details, :class_name => :CommissionDetail, :foreign_key => :commission_id

  mount_uploader :payment_img, PayUploader
  mount_uploader :payment_pdf, PdfUploader

  mount_uploader :invoice, CompressedFileUploader
end
