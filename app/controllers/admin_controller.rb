class AdminController < ApplicationController
  helper_method :search_params

  before_action :authenticate_user!

  def authenticate_user!
    unless logged_in?
      store_location
      redirect_to log_in_path
    end

    redirect_to root_path unless session[:user_type] == "w"
  end

  def deny_access!
    respond_to do |format|
      format.html { redirect_to root_path, flash: {info: t(:access_denied)} }
      format.any { head :not_found }
    end
  end

  def search_params
    return nil unless params[:class]
    params[:class][:search]
  end
end
