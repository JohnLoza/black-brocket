class StaticPagesController < ApplicationController
  layout "static_pages.html.erb"

  def index
    if logged_in?
      if session[:user_type] == "w"
        redirect_to admin_welcome_path and return
      elsif session[:user_type] == "d"
        redirect_to distributor_welcome_path and return
      end
    end

    @bgVideo = WebVideo.first
    @bgVideo = WebVideo.new if @bgVideo.nil?

    @bgImg = WebPhoto.where(name: "INITIAL").take
    @bgImg = WebPhoto.new if @bgImg.nil?

    @gallery_photos = WebPhoto.where(name: "GALLERY")
    @offers = WebOffer.all
    @welcome_message = WebInfo.where(name: "WELCOME_MESSAGE").take
    @services = WebInfo.where(name: ["HIGH_QUALITY","DISCOUNTS","EASY_SHOPPING","DISTRIBUTORS"])
  end

  def privacy_policy
    @privacy_policy = WebInfo.where(name: "PRIVACY_POLICY").take
    render :privacy_policy, layout: false
  end

  def terms_of_service
    @terms_of_service = WebInfo.where(name: "TERMS_OF_SERVICE").take
    render :terms_of_service, layout: false
  end

  def good_bye
    @client = Client.find_by!(hash_id: params[:id])
    render :good_bye, layout: false
  end

  def new_distributor_request
    @states = State.order_by_name
    @cities = Array.new
  end

  def create_distributor_request
    if DistributorCandidate.create(distributor_request_params)
      flash[:success] = "Tus datos fueron enviados, un representante se contactará contigo muy pronto."
    else
      flash[:info] = "Ocurrió un error al guardar tu información, inténtalo de nuevo por favor."
    end
    redirect_to root_path
  end

  def create_suggestion
    @suggestion = Suggestion.create(suggestion_params)

    respond_to do |format|
      format.js { render :create_suggestion, layout: false }
    end
  end

  def get_cities
    @cities = City.where(state_id: params[:state_id]).order_by_name

    respond_to do |format|
      format.json{ render json: @cities.as_json(only: [:id, :name, :lada]), status: 200 }
      format.any{ head :not_found }
    end
  end

  private
    def suggestion_params
      {name: params[:name], email: params[:email].strip, message: params[:message],
      telephone: params[:telephone]}
    end

    def distributor_request_params
      {name: params[:name], lastname: params[:lastname],
       mother_lastname: params[:mother_lastname],
       telephone: params[:telephone], cellphone: params[:cellphone],
       city_id: params[:city_id], email: params[:email]}
    end
end
