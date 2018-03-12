class Api::WorkersApi::DistributorsController < ApplicationController
  @@category = "ORDERS"

  def show
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    @current_user = SiteWorker.find_by(authentication_token: params[:authentication_token])
    if @current_user.blank?
      api_authentication_failed
      return
    end

    authorization_result = @current_user.is_authorized?(@@category, "CAPTURE_BATCHES")
    if !authorization_result.any?
      render :status => 200,
             :json => { :success => false, :info => "NO_ENOUGH_PERMISSIONS" }
    end

    order = Order.find_by(hash_id: params[:id])
    distributor = order.Distributor

    if distributor.blank?
      render :status => 200,
             :json => { :success => true, :info => "NO_DISTRIBUTOR" }
      return
    end

    data = Hash.new
    city = distributor.City

    data = {address: "", city: city.name, state: city.State.name, username: distributor.username, name: distributor.name,
            lastname: distributor.lastname, mother_lastname: distributor.mother_lastname,
            email: distributor.email, telephone: distributor.telephone, cellphone: distributor.cellphone,
            photo: User.getImage(distributor)}

    if distributor.show_address
      data[:address] = distributor.address
    end

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }
  end

end
