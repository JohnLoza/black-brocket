class Api::DistributorApi::VisitsController < ApiController
  @@user_type = :distributor

  def index
    client = Client.find_by!(hash_id: params[:id])

    visits = client.DistributorVisits.where.not(client_recognizes_visit: nil)
            .order(:created_at => :desc).paginate(page: params[:page], per_page: 25)

    data = Array.new
    data<<{per_page: 25}
    visits.each do |visit|
      data << {date: l(visit.visit_date, format: :long), visit_recognized: visit.client_recognizes_visit, treatment: visit.treatment_answer, extra_comments: visit.extra_comments}
    end

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }
  end

  def create
    client = Client.find_by!(hash_id: params[:id])

    today = Time.now.year.to_s+"-"+Time.now.month.to_s+"-"+Time.now.day.to_s
    visit = DistributorVisit.new(
                      distributor_id: @current_user.id,
                      client_id: client.id,
                      visit_date: today)

    if visit.save and client.update_attribute(:last_distributor_visit, today)
      render :status => 200,
             :json => { :success => true, :info => "SAVED" }
      return
    else
      render :status => 200,
             :json => { :success => false, :info => "SAVE_ERROR" }
      return
    end
  end

end
