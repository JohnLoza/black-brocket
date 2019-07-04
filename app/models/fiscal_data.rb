class FiscalData < ApplicationRecord
  belongs_to :Client, foreign_key: :client_id
  belongs_to :City, foreign_key: :city_id

  validates :client_id, :city_id, presence: true, numericality: { only_integer: true }

  validates :rfc, :name, :street, :col, :cp, :extnumber, presence: true
end
