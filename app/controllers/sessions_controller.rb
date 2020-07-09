class SessionsController < ApplicationController
  layout false

  def new
    loadBgImage() and return unless logged_in?

    redirect_to admin_welcome_path if session[:user_type] == "w"
    redirect_to distributor_welcome_path if session[:user_type] == "d"
    redirect_to products_path if session[:user_type] == "c"
  end

  def create
    worker = SiteWorker.find_by(email: params[:session][:email].downcase)
    redirect_back_or(admin_welcome_path) and return if try_log_in(worker, "w")
    
    distributor = Distributor.find_by(email: params[:session][:email].downcase)
    redirect_back_or(distributor_welcome_path) and return if try_log_in(distributor, "d")

    client = Client.find_by(email: params[:session][:email].downcase)
    if try_log_in(client, "c")
      unless client.email_verified
        flash[:info] = "Por favor confirma tu correo electrónico, en caso de no recibirlo 
          podemos <a href=\"#{client_resend_email_confirmation_path(client.hash_id)}\">reenviarlo</a>."
      end
      redirect_back_or(products_path) and return
    end

    flash.now[:danger] = "Email o contraseña incorrecto"
    loadBgImage()
    render :new, layout: false
  end

  def destroy
    log_out
    session.delete(:e_cart)
    redirect_to root_path
  end

  def forgot_password
    return unless params[:session] and params[:session][:email]
    user = Client.find_by(email: params[:session][:email])
    if user
      user.update_attributes(recover_pass_digest: user.new_token)
      SendRecoverPasswordEmailJob.perform_later(user)
      flash.now[:success] = "Hemos enviado un correo a tu dirección con las instrucciones de recuperación."
    else
      flash.now[:info] = "La dirección especificada no está registrada, puedes registrarte <a href=\"#{client_sign_up_path}\">aquí</a>"
    end
  end

  def recover_password
    user = Client.find_by!(recover_pass_digest: params[:token])
    unless params[:session] and params[:session][:password]
      render :recover_password, layout: false and return
    end

    user.update_attributes(recover_pass_digest: nil,
      password: params[:session][:password],
      password_confirmation: params[:session][:password])
    flash[:success] = "La contraseña ha sido cambiada!"
    redirect_to root_path
  end

  def update_password
    render_404 and return unless logged_in?

    case current_user.class.to_s
    when "Client"
      try_again_path = edit_client_client_path(current_user)
      success_path = products_path()
    when "Distributor"
      try_again_path = distributor_welcome_path()
      success_path = distributor_welcome_path()
    when "SiteWorker"
      try_again_path = admin_welcome_path()
      success_path = admin_welcome_path()
    end

    unless current_user.authenticate(params[:old_password])
      flash[:info] = "Contraseña incorrecta"
      redirect_to try_again_path and return
    end

    current_user.update_attributes(password: params[:new_password],
      password_confirmation: params[:new_password_confirmation])

    flash[:success] = "¡Contraseña cambiada!"
    redirect_to success_path
  end

  private
    def try_log_in(subject, type)
      if subject and subject.active? and subject.authenticate(params[:session][:password])
        log_in(subject, type)
        remember(subject, type) if params[:session][:remember_me] == "1"
        return true
      end
      return false
    end

    def loadBgImage()
      image = WebPhoto.find_by(name: "LOGIN")
      if image.blank?
        @bg_img = ActionController::Base.helpers.image_url "person-woman-coffee-cup-large.jpg"
      else
        @bg_img = image.photo.url
      end
    end
end
