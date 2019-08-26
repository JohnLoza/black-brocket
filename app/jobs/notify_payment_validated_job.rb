class NotifyPaymentValidatedJob < ApplicationJob
  queue_as :default

  def perform(order)
    ApplicationMailer.with(user: order.Client, order: order)
      .notify_payment_validated.deliver_now
  end
end
