class BankAccount < ActiveRecord::Base
  validates :bank_name, :account_number, :owner, presence: true
end
