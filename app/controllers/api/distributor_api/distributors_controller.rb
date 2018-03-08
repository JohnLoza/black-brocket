class Api::DistributorApi::DistributorsController < ApplicationController
  def index
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    current_user = Distributor.find_by(authentication_token: params[:authentication_token])
    if current_user.blank?
      api_authentication_failed
      return
    end

    regions = current_user.Regions
    home_img = current_user.home_img.url
    avatar = User.getImage(current_user)

    data = Hash.new
    data[:avatar] = avatar
    data[:home_img] = home_img
    array = Array.new
    regions.each do |region|
      array << region.name
    end
    data[:regions] = array

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }
  end

  def update_home_image
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    current_user = Distributor.find_by(authentication_token: params[:authentication_token])
    if current_user.blank?
      api_authentication_failed
      return
    end

    if !params[:distributor][:home_img].blank?
      if current_user.update_attribute(:home_img, params[:distributor][:home_img])
        render :status => 200,
               :json => { :success => true, :info => "SAVED" }
        return
      else
        render :status => 200,
               :json => { :success => false, :info => "SAVE_ERROR", :data => {formats_accepted: ["jpg","jpeg","png","gif"]} }
        return
      end
    else
      render :status => 200,
             :json => { :success => false, :info => "NO_IMAGE_FOUND" }
      return
    end
  end

  def get_username_n_photo
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    current_user = Distributor.find_by(authentication_token: params[:authentication_token])
    if current_user.blank?
      api_authentication_failed
      return
    end

    render :status => 200,
           :json => { :success => true, :info => "USER_DATA",
                      :data => {username: current_user.username, photo: User.getImage(current_user) }}
  end

  def notifications
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    current_user = Distributor.find_by(authentication_token: params[:authentication_token])
    if current_user.blank?
      api_authentication_failed
      return
    end

    notifications = current_user.Notifications
    data = Array.new
    notifications.each do |notification|
      if notification.url.include? "/distributor/client" and notification.url.include? "/messages"
        array = notification.url.split("/")
        data << {action: "CLIENT_MESSAGES", description: notification.description, client: array[3], seen: notification.seen, id: notification.id}
      end
    end

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }

  end
end
