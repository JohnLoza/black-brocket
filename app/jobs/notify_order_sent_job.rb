class NotifyOrderSentJob < ApplicationJob
  queue_as :default

  def perform(order)
    ApplicationMailer.with(user: order.Client, order: order)
      .notify_order_sent.deliver_now
  end
end
