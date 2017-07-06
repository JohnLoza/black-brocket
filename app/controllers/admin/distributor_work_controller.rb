class Admin::DistributorWorkController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_worker?
  layout "admin_layout.html.erb"

  @@category = "DISTRIBUTOR_WORK"

  def index
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @clients = Client.joins(:City).where(cities: {distributor_id: nil})
            .where(worker_id: nil)
            .paginate(page: params[:page], per_page: 25).includes(City: :State)
  end

  def take_client
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    client = Client.find_by(alph_key: params[:id])
    if client
      client.update_attribute(:worker_id, @current_user.id)
    end

    flash[:success] = "Cliente añadido a tu repertorio."
    redirect_to admin_distributor_work_clients_path
  end

  def my_clients
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @clients = @current_user.Clients
  end

  def prices
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @client = Client.find_by(alph_key: params[:id])

    if @client
      @product_prices = @client.ProductPrices
      @client_city = @client.City
      @products = Product.where(deleted: false).order(name: :asc)
    end # if @client #
  end

  def create_prices
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @client = Client.find_by(alph_key: params[:id])
    success = false
    if @client
      ActiveRecord::Base.transaction do
        @client.ProductPrices.delete_all
        params[:product].each do |param|
          ClientProduct.create(client_id: @client.id, product_id: param[0], client_price: param[1])
        end

        @client.update_attributes(has_custom_prices: true, is_new: false)
        success = true
      end
    end # if @client #

    flash[:success] = "Precios de #{@client.name} #{@client.lastname} actualizados" if success
    flash[:danger] = "Ocurrió un error al actualizar los precios" if !success
    redirect_to admin_distributor_work_my_clients_path
  end

  def messages
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @client = Client.find_by(alph_key: params[:id])
    if !@client
      redirect_to distributor_welcome_path
      return
    end

    if params[:notification]
      notification = Notification.find(params[:notification])
      notification.update_attribute(:seen, true)
    end

    @client_city = @client.City
    @messages = @current_user.ClientMessages.where(client_id: @client.id)
                  .order(created_at: :desc).paginate(page: params[:page], per_page: 25)

    @client_image = User.getImage(@client, :mini)
    @client_username = @client.username

    @distributor_image = User.getImage(@current_user, :mini)
    @distributor_username = @current_user.username

    @create_message_url = admin_distributor_work_client_messages_path(@client.alph_key)
  end

  def create_message
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @client = Client.find_by(alph_key: params[:id])
    if !@client
      redirect_to admin_welcome_path
      return
    end

    message = ClientDistributorComment.new(
            {client_id: @client.id, worker_id: @current_user.id,
             comment: params[:comment], is_from_client: false})
    message.save

    Notification.create(client_id: @client.id, icon: "fa fa-comments-o",
                    description: "El distribuidor respondió a tu mensaje",
                    url: client_my_distributor_path)

    flash[:success] = "Mensaje guardado."
    redirect_to admin_distributor_work_client_messages_path(@client.alph_key)
  end

  def orders
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @orders = Order.joins(:Client).where(clients: {worker_id: @current_user.id})
              .order(created_at: :desc).paginate(page: params[:page], per_page: 20)
  end

end
