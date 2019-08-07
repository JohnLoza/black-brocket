class SendConfirmationEmailJob < ApplicationJob
  queue_as :default

  def perform(user)
    ApplicationMailer.with(user: user).email_confirmation.deliver_now
  end
end
