class Mailer < ApplicationMailer
  def say_hello(email)
    mail(to: email, subject: "Mensaje enviado desde la applicación de BB!")
  end
end
