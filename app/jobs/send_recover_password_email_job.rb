class SendRecoverPasswordEmailJob < ApplicationJob
  queue_as :default

  def perform(user)
    ApplicationMailer.with(user: user).recover_password.deliver_now
  end
end
