class Api::DistributorApi::MessagesController < ApiController
  @@user_type = :distributor

  def index
    if params[:notification].present?
      notification = Notification.find(params[:notification])
      notification.update_attributes(seen: true)
    end

    client = Client.find_by!(hash_id: params[:id])

    messages = @current_user.ClientMessages.where(client_id: client.id)
                  .order(created_at: :desc).paginate(page: params[:page], per_page: 50)

    data = Hash.new
    data[:per_page] = 50
    data[:client_image] = client.avatar_url
    data[:client_username] = client.username
    data[:distributor_image] = @current_user.avatar_url
    data[:distributor_username] = @current_user.username

    array = Array.new
    messages.each do |msg|
      array << {date: l(msg.created_at, format: :long), comment: msg.comment, is_from_client: msg.is_from_client}
    end
    data[:messages] = array

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }
  end

  def create
    client = Client.find_by!(hash_id: params[:id])

    message = ClientDistributorComment.new(
            {client_id: client.id, distributor_id: @current_user.id,
             comment: params[:comment], is_from_client: false})
    message.save

    Notification.create(client_id: client.id, icon: "fa fa-comments-o",
                    description: "El distribuidor respondió a tu mensaje",
                    url: client_my_distributor_path)

    render :status => 200,
           :json => { :success => true, :info => "SAVED" }
  end
end
