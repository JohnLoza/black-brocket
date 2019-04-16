class SessionsController < ApplicationController

  def new
    if logged_in?
      redirect_to controller: "admin/welcome", action: :index if session[:user_type] == 'w'
      redirect_to controller: "distributor/admin", action: :index if session[:user_type] == 'd'
      redirect_to products_path if session[:user_type] == 'c'
      return
    end

    render :new, layout: false
  end

  def create
    worker = SiteWorker.find_by(email: params[:session][:email].downcase)
    if worker && worker.authenticate(params[:session][:password])
      log_in(worker, 'w')
      remember(worker, 'w') if params[:session][:remember_me] == '1'
      redirect_to controller: "admin/welcome", action: :index and return
    end

    distributor = Distributor.find_by(email: params[:session][:email].downcase)
    if distributor && distributor.authenticate(params[:session][:password])
      log_in(distributor, 'd')
      remember(distributor, 'd') if params[:session][:remember_me] == '1'
      redirect_to controller: "distributor/admin", action: :index and return
    end

    client = Client.find_by(email: params[:session][:email].downcase)
    if client && client.deleted_at == nil && client.authenticate(params[:session][:password])
      log_in(client, 'c')
      remember(client, 'c') if params[:session][:remember_me] == '1'
      if !client.email_verified
        flash[:info] = "Por favor confirma tu correo electrónico, en caso de no recibirlo puedes <a href=\"#{client_resend_email_confirmation_path(client.hash_id)}\">reenviarlo</a>."
      end
      redirect_to controller: "products" and return
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
end
