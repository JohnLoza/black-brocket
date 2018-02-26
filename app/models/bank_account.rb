class BankAccount < ApplicationRecord
  belongs_to :Bank

  validates :account_number, :interbank_clabe, :owner, :email, :RFC, presence: true
end
