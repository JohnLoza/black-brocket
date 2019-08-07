class NotifyOrderCanceledJob < ApplicationJob
  queue_as :default

  def perform(options = {})
    unless options and options[:user].present? and
      options[:order].present? and options[:reason].present?
      raise ArgumentError, "missing parameters required user, order and reason"
    end

    ApplicationMailer.with(user: options[:user], order: options[:order], 
      reason: options[:reason]).notify_order_canceled.deliver_now
  end
end