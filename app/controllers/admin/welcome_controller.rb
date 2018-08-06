class Admin::WelcomeController < AdminController

  def index
    
  end

  def suggestions
    deny_access! and return unless @current_user.has_permission_category?('comments_and_suggestions')

    @suggestions = Suggestion.unanswered.oldest.paginate(page: params[:page], per_page: 25)
  end

  def answer_suggestion
    deny_access! and return unless @current_user.has_permission?('comments_and_suggestions@answer')

    suggestion = Suggestion.find(params[:id])
    sugestion.update_attributes(answered: true)

    flash[:success] = "Respuesta a #{s.name} enviada!."
    redirect_to admin_suggestions_path
  end

  def notifications
    @notifications = @current_user.Notifications.recent.paginate(page: params[:page], per_page: 25)
  end

end
