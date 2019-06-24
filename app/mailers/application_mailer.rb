class ApplicationMailer < ActionMailer::Base
  default from: "BlackBrocket <noreply@blackbrocket.com>"
  default reply_to: "BlackBrocket <contacto@blackbrocket.com>"
  layout "mailer"

  def send_answer_to_candidate
    @candidate = params[:candidate]
    @answer = params[:answer]
    mail(to: @candidate.email, subject: "Respuesta a tu solicitud de distribuidor - BlackBrocket")
  end

  def send_answer_to_comment
    @comment = params[:comment]
    @answer = params[:answer]
    mail(to: @comment.email, subject: "Respuesta a tu comentario - BlackBrocket")
  end

  def send_confirmation_email
    @user = params[:user]
    mail(to: @user.email, subject: "Por favor, confirma tu dirección de correo electrónico - BlackBrocket")
  end

  def send_recover_password_email
    @user = params[:user]
    mail(to: @user.email, subject: "Recupera tu cuenta - BlackBrocket")
  end
end
