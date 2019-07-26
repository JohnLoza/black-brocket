class AdminController < ApplicationController
  helper_method :search_params
  before_action -> { current_user_is_a?(SiteWorker) }
  layout "admin_layout.html.erb"

  def deny_access!
    respond_to do |format|
      format.html { redirect_to admin_welcome_path, flash: {info: "Accesso denegado, falta de permisos"} }
      format.any { head :not_found }
    end
  end

  def search_params
    return nil unless params[:class]
    params[:class][:search]
  end
end
