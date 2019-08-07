class ApplicationMailer < ActionMailer::Base
  add_template_helper(MailerHelper)
  default from: "BlackBrocket <noreply@blackbrocket.com>"
  default reply_to: "BlackBrocket <contacto@blackbrocket.com>"
  layout "mailer"

  def answer_to_candidate
    @candidate = params[:candidate]
    @answer = params[:answer]
    mail(to: @candidate.email, subject: "Respuesta a tu solicitud de distribuidor - BlackBrocket")
  end

  def answer_to_comment
    @comment = params[:comment]
    @answer = params[:answer]
    mail(to: @comment.email, subject: "Respuesta a tu comentario - BlackBrocket")
  end

  def email_confirmation
    @user = params[:user]
    mail(to: @user.email, subject: "Por favor, confirma tu dirección de correo electrónico - BlackBrocket")
  end

  def recover_password
    @user = params[:user]
    mail(to: @user.email, subject: "Recupera tu cuenta - BlackBrocket")
  end

  def order_confirmation
    @user = params[:user]
    @order = params[:order]
    mail(to: @user.email, subject: "Termina tu compra - Black Brocket")
  end

  def message_notification
    @user = params[:user]
    @sender = params[:sender]
    @message = params[:message]
    
    subject = "Recibiste un mensaje de #{@sender.name} - Black Brocket"
    mail(to: @user.email, subject: subject, reply_to: @sender.email)
  end

  def product_question_answer
    @user = params[:user]
    @question = params[:question]
    @answer = params[:answer]

    product = @question.Product
    subject = "Respondieron a tu pregunta sobre #{product.name} - Black Brocket"

    mail(to: @user.email, subject: subject)
  end

  def notify_payment_rejected
    @user = params[:user]
    @order = params[:order]
    @reason = params[:reason]

    subject = "El pago de tu órden con folio #{@order.hash_id}
      ha sido rechazado - Black Brocket"

    mail(to: @user.email, subject: subject)
  end

  def notify_order_canceled
    @user = params[:user]
    @order = params[:order]
    @reason = params[:reason]

    subject = "Tu órden con folio #{@order.hash_id} ha sido cancelada - Black Brocket"

    mail(to: @user.email, subject: subject)
  end
end
