class FiscalData < ApplicationRecord
  belongs_to :Client, :foreign_key => :client_id
  belongs_to :City, :foreign_key => :city_id

  validates :client_id, :city_id, presence: true, numericality: { only_integer: true }

  validates :rfc, :name, :street, :col, :cp, :extnumber, presence: true

  validates :lastname,
        format: { with: /\A[a-zA-ZÑñáéíóúü\s\.']+\z/ },
        if: Proc.new { |f| !f.lastname.blank? and f.lastname != "" }

  validates :mother_lastname,
        format: { with: /\A[a-zA-ZÑñáéíóúü\s\.']+\z/ },
        if: Proc.new { |f| !f.mother_lastname.blank? and f.mother_lastname != "" }

end
