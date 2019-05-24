class TipsController < ApplicationController
  before_action :current_user_is_a_client?

  def index
    @tips = TipRecipe.all.order(updated_at: :desc)
      .paginate(page: params[:page], per_page: 15)
  end

  def create_comment
    @tip_id = params[:id]
    @comment = TipRecipeComment.new(tip_recipe_id: @tip_id, client_id: @current_user.id, 
      description: params[:tip_recipe_comment][:description])
    @comment.save

    respond_to do |format|
      format.html{ redirect_to tips_path }
      format.js { render :create_comment, layout: false }
    end
  end

  def show
    @tip = TipRecipe.find_by!(id: params[:id])

    @comments = @tip.Comments.order(created_at: :desc)
      .paginate(page: params[:page], per_page: 30).includes(:Client)
  end

end
