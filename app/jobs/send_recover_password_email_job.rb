class SendRecoverPasswordEmailJob < ApplicationJob
  queue_as :default

  def perform(user)
    ApplicationMailer.with(user: user).send_recover_password_email.deliver_now
  end
end
