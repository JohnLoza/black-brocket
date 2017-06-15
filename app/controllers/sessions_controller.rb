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
      if today_is_birthday?(worker.birthday)
        flash[:info] = happy_birthday_message()
      end
      log_in(worker, 'w')
      remember(worker, 'w') if params[:session][:remember_me] == '1'
      redirect_to controller: "admin/welcome", action: :index
      return
    end

    distributor = Distributor.find_by(email: params[:session][:email].downcase)
    if distributor && distributor.authenticate(params[:session][:password])
      if today_is_birthday?(distributor.birthday)
        flash[:info] = happy_birthday_message()
      end
      log_in(distributor, 'd')
      remember(distributor, 'd') if params[:session][:remember_me] == '1'
      redirect_to controller: "distributor/admin", action: :index
      return
    end

    client = Client.find_by(email: params[:session][:email].downcase)
    if client && client.deleted == false && client.authenticate(params[:session][:password])
      if today_is_birthday?(client.birthday)
        flash[:info] = happy_birthday_message()
      end
      log_in(client, 'c')
      remember(client, 'c') if params[:session][:remember_me] == '1'

      redirect_to controller: "products"
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

  private
    def today_is_birthday?(birthday)
      now = Time.now
      if birthday and now.month == birthday.month and now.day == birthday.day
        return true
      else
        return false
      end
    end

    def happy_birthday_message
      string = "Feliz cumpleaños! te desea el equipo de BlackBrocket."
      return string
    end
end
