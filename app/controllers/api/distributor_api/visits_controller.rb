class Api::DistributorApi::VisitsController < ApplicationController
  def index
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    current_user = Distributor.find_by(authentication_token: params[:authentication_token])
    if @current_user.blank?
      api_authentication_failed
      return
    end

    client = Client.find_by(alph_key: params[:id])
    if client.blank?
      render :status => 200,
             :json => { :success => false, :info => "CLIENT_NOT_FOUND" }
      return
    end

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
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    current_user = Distributor.find_by(authentication_token: params[:authentication_token])
    if @current_user.blank?
      api_authentication_failed
      return
    end

    client = Client.find_by(alph_key: params[:id])
    if client.blank?
      render :status => 200,
             :json => { :success => false, :info => "CLIENT_NOT_FOUND" }
      return
    end

    success = false
    today = Time.now.year.to_s+"-"+Time.now.month.to_s+"-"+Time.now.day.to_s
    visit = DistributorVisit.new(
                      distributor_id: @current_user.id,
                      client_id: client.id,
                      visit_date: today)

    success = true if visit.save and client.update_attribute(:last_distributor_visit, today)

    if success
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
