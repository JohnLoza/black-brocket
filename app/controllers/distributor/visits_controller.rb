class Distributor::VisitsController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_distributor?
  layout "distributor_layout.html.erb"

  def index
    region_ids = @current_user.Regions.map(&:id)
    @client = Client.where(city_id: region_ids).where(hash_id: params[:id]).take

    unless @client
      flash[:info] = "No encontramos al cliente."
      redirect_to distributor_clients_path and return
    end # if @client and @client.is_new #
    
    @visits = @client.DistributorVisits.order(:created_at => :desc).paginate(page: params[:page], per_page: 15)
  end

  def create
    @client = Client.find_by!(hash_id: params[:id])

    success = false
    visit = DistributorVisit.new(
                      distributor_id: @current_user.id,
                      client_id: @client.id,
                      visit_date: params[:visit_date])

    success = true if visit.save and @client.update_attribute(:last_distributor_visit, params[:visit_date])

    if success
      flash[:success] = "Visita guardada"
      redirect_to distributor_clients_path
    else
      flash[:info] = "Ocurrió un error al guardar la visita"
      redirect_to distributor_client_visits_path(@client.hash_id)
    end
  end

  def destroy
    visit = DistributorVisit.find(params[:id])
    visit.destroy if visit.client_recognizes_visit.nil?
    flash[:success] = "La visita ha sido cancelada!"
    redirect_to distributor_client_visits_path(params[:client_id])
  end
end
