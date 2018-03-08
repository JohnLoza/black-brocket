class Distributor::VisitsController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_distributor?
  layout "distributor_layout.html.erb"

  def index
    region_ids = current_user.Regions.map(&:id)
    @client = Client.where(city_id: region_ids).where(hash_id: params[:id]).take

    if !@client
      flash[:info] = "No encontramos a tu cliente."
      redirect_to distributor_clients_path
      return
    end # if @client and @client.is_new #
    
    @visits = @client.DistributorVisits.where("client_recognizes_visit is not null")
            .order(:created_at => :desc).paginate(page: params[:page], per_page: 15)
  end

  def create
    @client = Client.find_by(hash_id: params[:id])

    success = false
    today = Time.now.year.to_s+"-"+Time.now.month.to_s+"-"+Time.now.day.to_s
    visit = DistributorVisit.new(
                      distributor_id: current_user.id,
                      client_id: @client.id,
                      visit_date: today)

    success = true if visit.save and @client.update_attribute(:last_distributor_visit, today)

    if success
      flash[:success] = "Visita guardada"
      redirect_to distributor_clients_path
    else
      flash[:danger] = "Ocurrió un error al guardar la visita"
      redirect_to distributor_client_visits_path(@client.hash_id)
    end
  end
end
