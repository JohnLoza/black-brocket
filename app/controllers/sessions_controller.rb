class SessionsController < ApplicationController

  def new
    render :new, layout: false and return unless logged_in?

    redirect_to admin_welcome_path if session[:user_type] == 'w'
    redirect_to distributor_welcome_path if session[:user_type] == 'd'
    redirect_to products_path if session[:user_type] == 'c'
  end

  def create
    worker = SiteWorker.find_by(email: params[:session][:email].downcase)
    if try_log_in(worker, 'w')
      redirect_back_or(admin_welcome_path)
      return
    end 

    distributor = Distributor.find_by(email: params[:session][:email].downcase)
    if try_log_in(distributor, 'd')
      redirect_back_or(distributor_welcome_path)
      return
    end 

    client = Client.find_by(email: params[:session][:email].downcase)
    if try_log_in(client, 'c')
      unless client.email_verified
        flash[:info] = "Por favor confirma tu correo electrónico, en caso de no recibirlo podemos <a href=\"#{client_resend_email_confirmation_path(client.hash_id)}\">reenviarlo</a>."
      end
      redirect_back_or(products_path) 
      return
    end

    flash.now[:danger] = 'Email o contraseña incorrecto'
    @email = params[:session][:email].downcase
    render :new, layout: false
  end

  def destroy
    log_out
    session.delete(:e_cart)
    redirect_to root_path
  end

  def recover_password
    if params[:session] and params[:session][:email]
      user = Client.find_by(email: params[:session][:email])
      if user
        user.update_attributes(recover_pass_digest: user.new_token)
        SendRecoverPasswordEmailJob.perform_later(user)
        flash[:success] = "Hemos enviado un correo a tu dirección con las instrucciones de recuperación."
      else
        flash[:info] = "La dirección especificada no está registrada, puedes registrarte <a href=\"#{client_sign_up_path}\">aquí</a>"
      end
    end

    render :recover_password, layout: false
  end

  def update_password
    user = Client.find_by!(recover_pass_digest: params[:token])

    if params[:session] and params[:session][:password]
      user.update_attributes(recover_pass_digest: nil,
        password: params[:session][:password],
        password_confirmation: params[:session][:password])
      flash[:success] = "La contraseña ha sido actualizada!"
      redirect_to root_path and return
    end

    render :update_password, layout: false
  end

  private
    def try_log_in(subject, type)
      if subject and subject.active? and subject.authenticate(params[:session][:password])
        log_in(subject, type)
        remember(subject, type) if params[:session][:remember_me] == '1'
        return true
      end
      return false
    end
end
