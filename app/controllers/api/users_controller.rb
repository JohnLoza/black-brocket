class Api::UsersController < ApiController
  
  before_action except: :create do
    authenticate_user!(:client)
  end

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
    u = @current_user
    data = {username: u.username, email: u.email, street: u.street,
            colony: u.col, intnumber: u.intnumber, extnumber: u.extnumber,
            zipcode: u.cp, street_ref1: u.street_ref1, street_ref2: u.street_ref2,
            telephone: u.telephone, birthday: u.birthday, cellphone: u.cellphone,
            name: u.name, lastname: u.lastname, mother_lastname: u.mother_lastname, city: @current_user.City.id }

    render :status => 200,
           :json => { :success => true, :info => "USER_DATA",
                      :data => data, :state => @current_user.City.state_id  }
  end

  def get_username_n_photo
    render :status => 200,
           :json => { :success => true, :info => "USER_DATA",
                      :data => {username: @current_user.username, photo: @current_user.avatar_url }}
  end

  def update
    @current_user.city_id = params[:city_id]
    if @current_user.update_attributes(user_params)
      render :status => 200,
             :json => { :success => true, :info => "SAVED" }
    else
      render :status => 200,
             :json => { :success => false, :info => "SAVE_ERROR" }
    end
  end

  def destroy
    unless @current_user.authenticate(params[:password])
      render :status => 200,
             :json => { :success => false, :info => "PASSWORD_NOT_MATCH" }
      return
    end

    @current_user.delete_account_hash = @current_user.new_token

    if @current_user.destroy
      @current_user.update_attributes(authentication_token: nil)
      render :status => 200,
             :json => { :success => true, :info => "SAVED", delete_folio: @current_user.delete_account_hash }
    else
      render :status => 200,
             :json => { :success => false, :info => "SAVE_ERROR" }
    end

  end

  def notifications
    notifications = @current_user.Notifications.order(created_at: :desc)
      .limit(50).paginate(page: params[:page], per_page: 15)
    data = Array.new
    notifications.each do |notification|
      if notification.url.include? "/client/my_distributor"
        data << {action: "DISTRIBUTOR_MESSAGES", description: notification.description, seen: notification.seen, id: notification.id}
      elsif notification.url.include? "/client/user" and notification.url.include? "/orders"
        array = notification.url.split("/")
        data << {action: "ORDER_DETAILS", description: notification.description, order: array[5], seen: notification.seen, id: notification.id}
      end
    end

    not_seen_count = @current_user.Notifications.where(:seen => false).size
    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :not_seen_count => not_seen_count, :data => data }

  end

  def update_distributor_visit
    visit = DistributorVisit.find_by!(id: params[:visit])

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
    params.require(:client).permit(:username, :email, :email_confirmation,
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

  def generateAlphKey(letter, number)
    if number <= 9
      new_key = "000"+(number).to_s
    elsif number >= 10 and number < 100
      new_key = "00"+(number).to_s
    elsif number >= 100 and number < 1000
      new_key = "0"+(number).to_s
    else
      new_key = (number).to_s
    end

    return letter + new_key
  end
end
