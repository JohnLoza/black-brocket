class AdminController < ApplicationController
  helper_method :search_params

  before_action :authenticate_user!
  layout 'admin_layout.html.erb'

  def authenticate_user!
    unless logged_in?
      store_location
      redirect_to log_in_path
    end

    redirect_to root_path unless session[:user_type] == "w"
  end

  def deny_access!
    respond_to do |format|
      format.html { redirect_to admin_welcome_path, flash: {info: 'Acceso denegado, no tienes permiso para acceder a esta página'} }
      format.any { head :not_found }
    end
  end

  def search_params
    return nil unless params[:class]
    params[:class][:search]
  end
end
