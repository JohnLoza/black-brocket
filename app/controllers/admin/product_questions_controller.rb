class Admin::ProductQuestionsController < AdminController

  def index
    deny_access! and return unless @current_user.has_permission?('product_questions@answer')

    @questions = ProdQuestion.unanswered.order(created_at: :DESC)
      .paginate(:page => params[:page], :per_page => 20).includes(:Product, :Client)
  end

  def answered
    deny_access! and return unless @current_user.has_permission?('product_questions@answer')

    @questions = ProdQuestion.answered.order(updated_at: :DESC)
      .paginate(:page => params[:page], :per_page => 20).includes(:Product, :Client, Answer: :SiteWorker)
  end

  def create
    deny_access! and return unless @current_user.has_permission?('product_questions@answer')

    @answer = ProdAnswer.new(site_worker_id: @current_user.id, description: params[:prod_answer][:description])

    @question = ProdQuestion.find_by!(hash_id: params[:prod_answer][:question_id])
    @answer.question_id = @question.id

    @saved = false
    if @answer.save and @question.update_attributes(answered: true)
      @saved = true
      notification = Notification.create(client_id: @question.client_id, icon: "fa fa-comments-o",
                      description: "Pregunta respondida", url: client_question_answer_path(@question))
    end

    respond_to do |format|
      format.js { render :create, :layout => false }
    end
  end
end
