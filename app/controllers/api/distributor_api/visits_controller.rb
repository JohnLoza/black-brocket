class Api::DistributorApi::VisitsController < ApiController
  before_action do
    authenticate_user!(:distributor)
  end

  def index
    client = Client.find_by!(hash_id: params[:id])

    visits = client.DistributorVisits.order(created_at: :desc).paginate(page: params[:page], per_page: 25)

    data = Array.new
    data<<{per_page: 25}
    visits.each do |visit|
      data << {date: I18n.l(visit.visit_date, format: :long), visit_recognized: visit.client_recognizes_visit, 
        treatment: visit.treatment_answer, extra_comments: visit.extra_comments, id: visit.id}
    end

    render status: 200, json: {success: true, info: "DATA_RETURNED", data: data}
  end

  def create
    client = Client.find_by!(hash_id: params[:id])

    visit = DistributorVisit.new(distributor_id: @current_user.id,
      client_id: client.id, visit_date: params[:visit_date])

    if visit.save and client.update_attribute(:last_distributor_visit, params[:visit_date])
      render status: 200, json: {success: true, info: "SAVED"} and return
    else
      render status: 200, json: {success: false, info: "SAVE_ERROR"} and return
    end
  end

  def destroy
    visit = DistributorVisit.find(params[:id])
    visit.destroy if visit.client_recognizes_visit.nil?
    render status: 200, json: {success: true, info: "DELETED"} and return
  end

end
