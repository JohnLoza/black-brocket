class Admin::WelcomeController < AdminController

  def index
    
  end

  def suggestions
    deny_access! and return unless @current_user.has_permission_category?('comments_and_suggestions')
    params[:controller] = "admin/suggestions"

    @suggestions = Suggestion.unanswered.oldest.paginate(page: params[:page], per_page: 25)
  end

  def answer_suggestion
    deny_access! and return unless @current_user.has_permission?('comments_and_suggestions@answer')

    suggestion = Suggestion.find(params[:id])
    SendAnswerToCommentJob.perform_later(suggestion, params[:answer])
    suggestion.update_attributes(answered: true)

    flash[:success] = "Respuesta a #{suggestion.name} enviada!."
    redirect_to admin_suggestions_path
  end

  def notifications
    @notifications = @current_user.Notifications.recent.limit(100).paginate(page: params[:page], per_page: 25)
  end

  def update_ui_theme
    @current_user.update_attribute(:ui_theme, params[:theme])
    render :status => 200, json: { success: true, new_theme: params[:theme] }
  end

end
