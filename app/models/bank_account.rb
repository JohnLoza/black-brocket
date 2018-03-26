class BankAccount < ApplicationRecord
  include Searchable
  belongs_to :Bank, class_name: :Bank, foreign_key: :bank_id

  validates :account_number, :interbank_clabe, :owner, :email, :RFC, presence: true
end
