class Api::DistributorApi::ClientsController < ApplicationController
  def index
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    @current_user = Distributor.find_by!(authentication_token: params[:authentication_token])
    if @current_user.blank?
      api_authentication_failed
      return
    end

    regions = @current_user.Regions.map(&:id)
    clients = Client.where(id: regions).order(updated_at: :DESC).paginate(:page => params[:page], :per_page => 20).includes(City: :State)

    data = Array.new
    data<<{per_page: 20}
    clients.each do |client|
      data << {hash_id: client.hash_id, username: client.username, city: client.City.name, state: client.City.State.name,
               last_visit: client.last_distributor_visit, last_revision: client.last_distributor_revision, photo: User.avatar_url(client),
               telephone: client.telephone, cellphone: client.cellphone, lada: client.City.lada}
    end

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }
  end

  def show
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    @current_user = Distributor.find_by!(authentication_token: params[:authentication_token])
    if @current_user.blank?
      api_authentication_failed
      return
    end

    client = Client.find_by!(hash_id: params[:id])
    if client.blank?
      render :status => 200,
             :json => { :success => false, :info => "CLIENT_NOT_FOUND" }
      return
    end

    data = {username: client.username, email: client.email, street: client.street,
            colony: client.col, intnumber: client.intnumber, extnumber: client.extnumber,
            zipcode: client.cp, street_ref1: client.street_ref1, street_ref2: client.street_ref2,
            telephone: client.telephone, birthday: client.birthday, cellphone: client.cellphone,
            name: client.name, lastname: client.lastname, mother_lastname: client.mother_lastname,
            city: client.City.name, state: client.City.State.name, created_at: client.created_at, updated_at: client.updated_at }

    render :status => 200,
           :json => { :success => true, :info => "USER_DATA",
                      :data => data }
  end
end
