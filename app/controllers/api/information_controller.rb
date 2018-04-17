class Api::InformationController < ApiController
  skip_before_action :authenticate_user!, except: :ecart_info
  @@user_type = :client

  def privacy_policy
    data = WebInfo.where(name: "PRIVACY_POLICY").take
    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED",
                      :data => data.description  }
  end

  def terms_of_service
    data = WebInfo.where(name: "TERMS_OF_SERVICE").take
    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED",
                      :data => data.description }
  end

  def tips
    tips = TipRecipe.all.order(updated_at: :desc)
            .paginate(page: params[:page], per_page: 15)

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED",
                      :data => tips, :per_page => 15 }
  end

  def contact
    suggestion = Suggestion.new(suggestion_params)

    if suggestion.save
      render :status => 200,
             :json => { :success => true, :info => "SAVED" }
    else
      render :status => 200,
             :json => { :success => false, :info => "SAVE_ERROR" }
    end
  end

  def ecart_info
    warehouse = @current_user.City.State.Warehouse

    notice = WebInfo.where(name: "ECART_NOTICE").take
    data = {shipping_cost: warehouse.shipping_cost, wholesale: warehouse.wholesale, ecart_notice: notice.description}
    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", data: data }
  end

  private
  def suggestion_params
    {name: params[:name], email: params[:email].strip, message: params[:message]}
  end

end
