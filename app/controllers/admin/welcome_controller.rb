class Admin::WelcomeController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_worker?
  layout "admin_layout.html.erb"

  @@category = "COMMENTS_AND_SUGGESTIONS"

  def index
    authorization_result = @current_user.is_authorized?(nil, nil, false)
    return if !process_authorization_result(authorization_result)

    # Mailer.say_hello("lozabucio.jony@gmail.com").deliver_now
  end

  def suggestions
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @suggestions = Suggestion.where(answered: false).order(created_at: :ASC).paginate(page: params[:page], per_page: 5)
  end

  def answer_suggestion
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    s = Suggestion.find(params[:id])
    if s
      s.update_attributes(answered: true)
      # s.update_attributes(response: params[:response], answered: true)

      flash[:success] = "Respuesta a #{s.name} enviada!."
      redirect_to admin_suggestions_path
    else
      flash[:warning] = "No se encontró el comentario o sugerencia..."
      redirect_to admin_suggestions_path
    end
  end

  def notifications
    authorization_result = @current_user.is_authorized?(nil, nil, false)
    return if !process_authorization_result(authorization_result)

    @notifications = @current_user.Notifications.order(created_at: :desc)
                      .limit(50).paginate(page: params[:page], per_page: 15)
  end

  # deprecated
  def configurations
    redirect_to root_path if !@current_user.is_admin
    authorization_result = @current_user.is_authorized?(nil,nil,false)
    return if !process_authorization_result(authorization_result)
  end

  # deprecated
  def update_configurations
    redirect_to root_path if !@current_user.is_admin
    authorization_result = @current_user.is_authorized?(nil,nil,false)
    return if !process_authorization_result(authorization_result)

    flash[:success] = "Configuración actualizada"
    redirect_to admin_welcome_path
  end

  private

end
