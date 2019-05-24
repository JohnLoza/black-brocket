class Distributor::AdminController < ApplicationController
  before_action :current_user_is_a_distributor?
  layout "distributor_layout.html.erb"

  def index
    @regions = @current_user.Regions
  end

  def update_home_image
    @current_user.update_attribute(:home_img, params[:distributor][:home_img])
    flash[:success] = "Imagen guardada"
    redirect_to distributor_welcome_path
  end

  def notifications
    @notifications = @current_user.Notifications.order(created_at: :desc)
      .limit(50).paginate(page: params[:page], per_page: 15)
  end

  def update_ui_theme
    @current_user.update_attribute(:ui_theme, params[:theme])
    render status: 200, json: {success: true, new_theme: params[:theme] }
  end

end
