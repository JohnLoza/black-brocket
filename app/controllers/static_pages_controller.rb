class StaticPagesController < ApplicationController
  # require 'net/http'
  layout "static_pages.html.erb"

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
    @client = Client.find_by!(hash_id: params[:id])
    render :good_bye, layout: false
  end

  def new_distributor_request
    @states = State.order_by_name
    @cities = Array.new
  end

  def create_distributor_request
    candidate = DistributorCandidate.new(distributor_request_params)
    if candidate.save
      flash[:success] = "Tus datos fueron enviados, un representante se contactará contigo muy pronto."
    else
      flash[:info] = "Ocurrió un error al guardar tu información, inténtalo de nuevo por favor."
    end
    redirect_to root_path
  end

  def create_suggestion
    if !params[:name].blank? and !params[:email].blank? and !params[:message].blank?
      suggestion = Suggestion.new(suggestion_params)
      @saved = suggestion.save ? true : false
    end

    respond_to do |format|
      format.js { render :create_suggestion, :layout => false }
    end
  end

  def get_cities
    @cities = City.where(:state_id => params[:state_id]).order_by_name

    respond_to do |format|
      format.json{ render json: @cities.as_json(only: [:id, :name, :lada]), status: 200 }
      format.any{ head :not_found }
    end
  end

  def get_city_lada
    @city = nil
    if (params[:city] != nil && params[:city] != '')
      @city = City.find_by!(id: params[:city])
    end

    respond_to do |format|
      format.js { render :get_city_lada, :layout => false }
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

    def fill_ladas_in_database
      # need to uncomment require 'net/http' at the top of the file
      City.where(lada: nil).includes(:State).each do |city|
        state_name = city.State.name
        state_name = "México" if state_name == "Edo. México"
        if state_name == "Ciudad de México"
          city.update_attributes(lada: "55")
          next
        end

        url = URI.parse("http://telmex.com/web/buscador?q=#{CGI.escape city.name}+#{CGI.escape state_name}&output=xml_no_dtd&oe=UTF-8&ie=UTF-8&client=_nuevo_telmex_claves_lada&proxystylesheet=_nuevo_telmex_claves_lada&entqr=3&entqrm=0&ud=1&getfields=*&site=claves_lada&filter=0&requiredfields=&giro=Mostrar+todo&estado=Seleccione+uno")
        req = Net::HTTP::Get.new(url.to_s)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }

        matches = res.body.match(/(cveLada).*\n.*\n.*div/)
        if matches.nil?
          puts "--- No lada found for #{city.name}, #{state_name} ---"
          next
        end
        num = matches.to_s.match(/\d+/)

        city.update_attributes(lada: num.to_s)
        puts "--- updating lada for #{city.name}, #{state_name}| lada: #{num.to_s}"
      end
    end
end
