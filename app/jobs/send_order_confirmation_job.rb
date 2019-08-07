class SendOrderConfirmationJob < ApplicationJob
  queue_as :default

  def perform(user, order)
    ApplicationMailer.with(user: user, order: order)
      .order_confirmation.deliver_now
  end
end
