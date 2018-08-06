class ApplicationMailer < ActionMailer::Base
  default from: 'noreply@blackbrocket.com'
  layout 'mailer'

  def send_confirmation_email
    @user = params[:user]
    mail(to: @user.email, subject: 'Por favor, confirma tu dirección de correo electrónico - BlackBrocket')
  end
end
