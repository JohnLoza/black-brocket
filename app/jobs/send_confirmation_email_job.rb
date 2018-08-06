class SendConfirmationEmailJob < ApplicationJob
  queue_as :default

  def perform(user)
    ApplicationMailer.with(user: user).send_confirmation_email.deliver_now
  end
end
