class Admin::ProductQuestionsController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_worker?
  layout "admin_layout.html.erb"

  @@category = "PRODUCT_QUESTIONS"

  def index
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @questions = ProdQuestion.where(answered: false).order(created_at: :DESC)
                             .paginate(:page => params[:page], :per_page => 20).includes(:Product, :Client)
  end

  def answered
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @questions = ProdQuestion.where(answered: true).order(updated_at: :DESC)
                             .paginate(:page => params[:page], :per_page => 20).includes(:Product, :Client, Answer: :SiteWorker)
  end

  def create
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @answer = ProdAnswer.new(site_worker_id: @current_user.id,
                             description: params[:prod_answer][:description])

    @question = ProdQuestion.find_by!(hash_id: params[:prod_answer][:question_id])
    @answer.question_id = @question.id

    if @answer.save and @question.update_attributes(answered: true)
      @saved = true
      notification = Notification.create(client_id: @question.client_id, icon: "fa fa-comments-o",
                      description: "Pregunta respondida", url: client_question_answer_path(@question.id))
    else
      @saved = false
    end

    respond_to do |format|
      format.js { render :create, :layout => false }
    end
  end
end
