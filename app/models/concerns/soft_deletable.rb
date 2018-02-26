require 'active_support/concern'

# For this concern to work, generate a migration for the model adding
# a datetime 'deleted_at' attribute with nil as default
module SoftDeletable
  extend ActiveSupport::Concern

  included do
    attr_accessor :really_destroy
    scope :active,   -> { where(deleted_at: nil) }
    scope :inactive, -> { where.not(deleted_at: nil) }
  end

  def active?
    !deleted_at.present?
  end

  def inactive?
    deleted_at.present?
  end

  def destroy
    if self.really_destroy
      super
    else
      update_attributes(deleted_at: Time.now)
    end
  end

  def restore
    update_attributes(deleted_at: nil)
  end

  def really_destroy!
    self.really_destroy = true
    self.destroy
  end

  class_methods do
    # class methods go here #
  end
end
