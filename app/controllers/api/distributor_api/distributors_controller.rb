class Api::DistributorApi::DistributorsController < ApiController
  before_action do
    authenticate_user!(:distributor)
  end

  def index
    regions = @current_user.Regions

    data = Hash.new
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
    notifications = @current_user.Notifications.order(created_at: :desc)
      .limit(50).paginate(page: params[:page], per_page: 15)
    data = Array.new
    notifications.each do |notification|
      if notification.url.include? "/distributor/client" and notification.url.include? "/messages"
        array = notification.url.split("/")
        data << {action: "CLIENT_MESSAGES", description: notification.description, client: array[3], seen: notification.seen, id: notification.id}
      end
    end

    not_seen_count = @current_user.Notifications.where(:seen => false).size
    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :not_seen_count => not_seen_count, :data => data }

  end
end
