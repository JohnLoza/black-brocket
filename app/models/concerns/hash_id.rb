require 'active_support/concern'

# For this concern to work, generate a migration for the model
# adding a string 'hash_id' attribute
module HashId
  extend ActiveSupport::Concern

  included do
    before_create :generate_hash_id
  end

  def to_param
    hash_id
  end

  private
  def generate_hash_id
    loop do
      self.hash_id = Utils.new_alphanumeric_token unless self.hash_id.present?
      break unless hash_id_taken?(self.hash_id)
    end
  end

  def hash_id_taken?(hash_id)
    self.class.find_by(hash_id: hash_id)
  end
end
