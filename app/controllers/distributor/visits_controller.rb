class Distributor::VisitsController < ApplicationController
  before_action -> { user_should_be(Distributor) }
  layout "distributor_layout.html.erb"

  def index
    region_ids = @current_user.Regions.map(&:id)
    @client = Client.find_by!(hash_id: params[:id], city_id: region_ids)
    
    @visits = @client.DistributorVisits.order(created_at: :desc)
      .paginate(page: params[:page], per_page: 15)
  end

  def create
    @client = Client.find_by!(hash_id: params[:id])

    DistributorVisit.create(distributor_id: @current_user.id,
      client_id: @client.id, visit_date: params[:visit_date])

    flash[:success] = "Visita guardada"
    redirect_to distributor_clients_path
  end

  def destroy
    visit = DistributorVisit.find(params[:id])
    visit.destroy if visit.client_recognizes_visit.nil?
    
    flash[:success] = "La visita ha sido cancelada!"
    redirect_to distributor_client_visits_path(params[:client_id])
  end
end
