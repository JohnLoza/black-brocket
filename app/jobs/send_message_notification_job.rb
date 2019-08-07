class SendMessageNotificationJob < ApplicationJob
  queue_as :default

  def perform(options = {})
    unless options and options[:user].present? and
      options[:sender].present? and options[:message].present?
      raise ArgumentError, "Missing parameter required user, sender and message"
    end

    ApplicationMailer.with(user: options[:user], sender: options[:sender],
      message: options[:message]).message_notification.deliver_now
  end
end
