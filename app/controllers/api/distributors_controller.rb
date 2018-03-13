class Api::DistributorsController < ApplicationController
  def create_candidate
    candidate = DistributorCandidate.new(distributor_request_params)
    if candidate.save
      render :status => 200,
             :json => { :success => true, :info => "SAVED" }
    else
      render :status => 200,
             :json => { :success => false, :info => "SAVE_ERROR" }
    end
  end

  def show
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    @current_user = Client.find_by!(authentication_token: params[:authentication_token])
    if @current_user.blank?
      api_authentication_failed
      return
    end

    distributor_is_a_worker = false
    distributor = @current_user.City.Distributor
    if !distributor and !@current_user.worker_id.blank?
      distributor = @current_user.Worker
      distributor_is_a_worker = true
    end

    if distributor.blank?
      render :status => 200,
             :json => { :success => false, :info => "DISTRIBUTOR_NOT_FOUND" }
      return
    end

    city = distributor.City
    data = {address: "", city: city.name, state: city.State.name, username: distributor.username, name: distributor.name,
            lastname: distributor.lastname, mother_lastname: distributor.mother_lastname,
            email: distributor.email, telephone: distributor.telephone, cellphone: distributor.cellphone,
            photo: User.getImage(distributor)}

    if !distributor_is_a_worker
      if distributor.show_address
        data[:address] = distributor.address
      end
    end

    render :status => 200,
           :json => { :success => true, :info => "DISTRIBUTOR_DATA", :data => data }
  end

  def messages
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    @current_user = Client.find_by!(authentication_token: params[:authentication_token])
    if @current_user.blank?
      api_authentication_failed
      return
    end

    if !params[:notification].blank?
      notification = Notification.find(params[:notification])
      notification.update_attributes(seen: true)
    end

    messages = @current_user.DistributorMessages.all.order(:created_at => :desc)
                  .paginate(page: params[:page], :per_page => 50)

    data = Array.new
    messages.each do |message|
      data << {is_from_client: message.is_from_client, comment: message.comment, datetime: l(message.created_at, format: :long)}
    end

    render :status => 200,
           :json => { :success => true, :info => "MESSAGES_DATA", :data => data }
  end

  def create_message
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    @current_user = Client.find_by!(authentication_token: params[:authentication_token])
    if @current_user.blank?
      api_authentication_failed
      return
    end

    distributor_is_a_worker = false
    distributor = nil
    if !@current_user.worker_id.blank?
      distributor = @current_user.Worker
      distributor_is_a_worker = true
    else
      distributor = @current_user.City.Distributor
    end

    message = ClientDistributorComment.new({client_id: @current_user.id, comment: params[:comment], is_from_client: true})
    if !distributor_is_a_worker
      message.distributor_id = distributor.id
      Notification.create(distributor_id: distributor.id, icon: "fa fa-comments-o",
                      description: "El usuario " + @current_user.username + " te envió un mensaje",
                      url: distributor_client_messages_path(@current_user.hash_id))
    else
      message.worker_id = distributor.id
      Notification.create(worker_id: distributor.id, icon: "fa fa-comments-o",
                      description: "El usuario " + @current_user.username + " te envió un mensaje",
                      url: admin_distributor_work_client_messages_path(@current_user.hash_id))
    end

    if message.save
      render :status => 200,
             :json => { :success => true, :info => "SAVED" }
    else
      render :status => 200,
             :json => { :success => false, :info => "SAVE_ERROR", :data => data }
    end
  end

  private
  def distributor_request_params
    {name: params[:name], lastname: params[:lastname],
     mother_lastname: params[:mother_lastname],
     telephone: params[:telephone], cellphone: params[:cellphone],
     city_id: params[:city_id], email: params[:email]}
  end
end
