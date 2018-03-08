class Api::WorkersApi::ClientsController < ApplicationController
  @@category = "ORDERS"

  def show
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    current_user = SiteWorker.find_by(authentication_token: params[:authentication_token])
    if current_user.blank?
      api_authentication_failed
      return
    end

    authorization_result = current_user.is_authorized?(@@category, "CAPTURE_BATCHES")
    if !authorization_result.any?
      render :status => 200,
             :json => { :success => false, :info => "NO_ENOUGH_PERMISSIONS" }
    end

    order = Order.find_by(hash_id: params[:id])
    if order.blank?
      render :status => 200,
             :json => { :success => false, :info => "ORDER_NOT_FOUND" }
      return
    end
    c = order.Client

    data = {username: c.username, email: c.email, street: c.street,
            colony: c.col, intnumber: c.intnumber, extnumber: c.extnumber,
            zipcode: c.cp, street_ref1: c.street_ref1, street_ref2: c.street_ref2,
            telephone: c.telephone, birthday: c.birthday, cellphone: c.cellphone,
            name: c.name, lastname: c.lastname, mother_lastname: c.mother_lastname,
            photo: User.getImage(c)}

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED",
                      :data => data, city_name: c.City.name, state_name: c.City.State.name  }
  end

end
