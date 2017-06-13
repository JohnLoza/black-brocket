class StaticPagesController < ApplicationController
  layout "static_pages.html.erb"

  @@base_file_path = "app/views"
  @@replaceable_path = "/shared/products/"

  def index
    if !session[:user_type].blank?
      if session[:user_type] == 'w'
        redirect_to admin_welcome_path
        return
      elsif session[:user_type] == 'd'
        redirect_to distributor_welcome_path
        return
      end
    end

    @bgVideo = WebVideo.first
    @bgVideo = WebVideo.new if @bgVideo.nil?

    @bgImg = WebPhoto.where(name: "INITIAL").take
    @bgImg = WebPhoto.new if @bgImg.nil?

    @photos = WebPhoto.where(name: "GALLERY")
    @offers = WebOffer.all
    @texts = WebInfo.where(name: "WELCOME_MESSAGE").take
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
    @client = Client.find_by(alph_key: params[:id])
    render :good_bye, layout: false
  end

  def new_distributor_request
    @states = State.all.order(:name)
    @cities = Array.new
  end

  def create_distributor_request
    candidate = DistributorCandidate.new(distributor_request_params)
    if candidate.save
      flash[:success] = "Tus datos fueron enviados, un representante se contactará contigo muy pronto."
    else
      flash[:danger] = "Ocurrió un error al guardar tu información, intentalo de nuevo por favor."
    end
    redirect_to root_path
  end

  def create_suggestion
    suggestion = Suggestion.new(suggestion_params)

    @saved = false
    @saved = true if suggestion.save

    respond_to do |format|
      format.js { render :create_suggestion, :layout => false }
    end
  end

  def get_cities
    if (params[:state] == nil || params[:state] == '')
      @cities = Array.new
    else
      @cities = City.where(:state_id => params[:state]).order(:name);
    end

    respond_to do |format|
      format.js { render :get_cities, :layout => false }
    end
  end

  private
    def suggestion_params
      {name: params[:name], email: params[:email].strip, message: params[:message]}
    end

    def distributor_request_params
      {name: params[:name], lastname: params[:lastname],
       mother_lastname: params[:mother_lastname],
       telephone: params[:telephone], cellphone: params[:cellphone],
       city_id: params[:city_id], email: params[:email]}
    end
end
