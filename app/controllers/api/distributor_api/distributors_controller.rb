class Api::DistributorApi::DistributorsController < ApiController
  before_action do
    authenticate_user!(:distributor)
  end

  def index
    regions = @current_user.Regions
    home_img = @current_user.home_img.url
    avatar = @current_user.avatar_url

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
    if !params[:distributor][:home_img].blank?
      if @current_user.update_attribute(:home_img, params[:distributor][:home_img])
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
    render :status => 200,
           :json => { :success => true, :info => "USER_DATA",
                      :data => {username: @current_user.username, photo: @current_user.avatar_url }}
  end

  def notifications
    notifications = @current_user.Notifications
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
