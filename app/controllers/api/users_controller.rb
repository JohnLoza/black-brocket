class Api::UsersController < ApplicationController
  def create
    client = Client.new(user_params)
    client.city_id = params[:city_id]

    if client.save
      client.update_attributes(:hash_id => generateAlphKey("C", client.id), :authentication_token => SecureRandom.urlsafe_base64(16))

      render :status => 200,
             :json => { :success => true, :info => "SAVED",
                        :data => { auth_token: client.authentication_token } }
    else
      client.errors.each do |field, msg|
        puts "--- #{field} #{msg} ---"
      end
      render :status => 200,
             :json => { :success => false, :info => "SAVE_ERROR" }
    end

  end

  def show
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    current_user = Client.find_by(authentication_token: params[:authentication_token])
    if current_user.blank?
      api_authentication_failed
      return
    end

    u = current_user
    data = {username: u.username, email: u.email, street: u.street,
            colony: u.col, intnumber: u.intnumber, extnumber: u.extnumber,
            zipcode: u.cp, street_ref1: u.street_ref1, street_ref2: u.street_ref2,
            telephone: u.telephone, birthday: u.birthday, cellphone: u.cellphone,
            name: u.name, lastname: u.lastname, mother_lastname: u.mother_lastname, city: current_user.City.id }

    render :status => 200,
           :json => { :success => true, :info => "USER_DATA",
                      :data => data, :state => current_user.City.state_id  }
  end

  def get_username_n_photo
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    current_user = Client.find_by(authentication_token: params[:authentication_token])
    if current_user.blank?
      api_authentication_failed
      return
    end

    render :status => 200,
           :json => { :success => true, :info => "USER_DATA",
                      :data => {username: current_user.username, photo: User.getImage(current_user) }}
  end

  def update
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    current_user = Client.find_by(authentication_token: params[:authentication_token])
    if current_user.blank?
      api_authentication_failed
      return
    end

    current_user.city_id = params[:city_id]
    if current_user.update_attributes(user_params)
      render :status => 200,
             :json => { :success => true, :info => "SAVED" }
    else
      render :status => 200,
             :json => { :success => false, :info => "SAVE_ERROR" }
    end
  end

  def destroy
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    current_user = Client.find_by(authentication_token: params[:authentication_token])
    if current_user.blank?
      api_authentication_failed
      return
    end

    if !current_user.authenticate(params[:password])
      render :status => 200,
             :json => { :success => false, :info => "PASSWORD_NOT_MATCH" }
      return
    end

    current_user.deleted=true
    current_user.delete_account_hash= random_hash_id(12).upcase

    if current_user.save
      render :status => 200,
             :json => { :success => true, :info => "SAVED", delete_folio: current_user.delete_account_hash }
    else
      render :status => 200,
             :json => { :success => false, :info => "SAVE_ERROR" }
    end

  end

  def notifications
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    current_user = Client.find_by(authentication_token: params[:authentication_token])
    if current_user.blank?
      api_authentication_failed
      return
    end

    notifications = current_user.Notifications
    data = Array.new
    notifications.each do |notification|
      if notification.url.include? "/client/my_distributor"
        data << {action: "DISTRIBUTOR_MESSAGES", description: notification.description, seen: notification.seen, id: notification.id}
      elsif notification.url.include? "/client/user" and notification.url.include? "/orders"
        array = notification.url.split("/")
        data << {action: "ORDER_DETAILS", description: notification.description, order: array[5], seen: notification.seen, id: notification.id}
      end
    end

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }

  end

  def update_distributor_visit
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    current_user = Client.find_by(authentication_token: params[:authentication_token])
    if current_user.blank?
      api_authentication_failed
      return
    end

    visit = DistributorVisit.find(params[:visit])
    if visit.blank?
      render :status => 200,
             :json => { :success => false, :info => "VISIT_NOT_FOUND" }
      return
    end

    if visit.update_attributes(visit_params)
      render :status => 200,
             :json => { :success => true, :info => "SAVED" }
    else
      render :status => 200,
             :json => { :success => false, :info => "SAVE_ERROR" }
    end

  end

  private
  def user_params
    params.require(:client).permit(:username, :email,
                                   :street, :col, :intnumber, :extnumber,
                                   :cp, :street_ref1, :street_ref2, :telephone,
                                   :password, :password_confirmation, :birthday,
                                   :photo, :cellphone,
                                   :name, :lastname, :mother_lastname)
  end

  def visit_params
    params.require(:distributor_visit).permit(:client_recognizes_visit,
                                       :treatment_answer, :extra_comments)
  end
end
