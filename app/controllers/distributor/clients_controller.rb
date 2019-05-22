class Distributor::ClientsController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_distributor?
  layout "distributor_layout.html.erb"

  def index
    region_ids = @current_user.Regions.map(&:id)
    @clients = Client.where(city_id: region_ids).order(updated_at: :DESC).paginate(page: params[:page], per_page: 20).includes(City: :State)
  end

  def show
    region_ids = @current_user.Regions.map(&:id)
    @client = Client.where(city_id: region_ids).where(hash_id: params[:id]).take

    unless @client
      flash[:info] = "No encontramos al cliente."
      redirect_to distributor_clients_path and return
    end # if @client and @client.is_new #
  end

  def prices
    region_ids = @current_user.Regions.map(&:id)
    @client = Client.where(city_id: region_ids).where(hash_id: params[:id]).take

    unless @client
      flash[:info] = "No encontramos al cliente."
      redirect_to distributor_clients_path and return
    end # if @client and @client.is_new #

    @product_prices = @client.ProductPrices
    @client_city = @client.City
    @products = Product.where(deleted_at: nil).order(name: :asc)

    @current_user.updateRevision(@client)
  end

  def create_prices
    @client = Client.find_by!(hash_id: params[:id])
    ActiveRecord::Base.transaction do
      @client.ProductPrices.destroy_all
      params[:product].each do |product_id|
        ClientProduct.create(client_id: @client.id, product_id: product_id, client_price: params[:product][product_id])
      end

      @client.update_attributes(has_custom_prices: true, is_new: false)
      flash[:success] = "Precios de #{@client.name} #{@client.lastname} actualizados"
    end

    flash[:info] = "Ocurrió un error al actualizar los precios" unless flash[:success].present?
    redirect_to distributor_clients_path
  end

  def messages
    region_ids = @current_user.Regions.map(&:id)
    @client = Client.where(city_id: region_ids).where(hash_id: params[:id]).take

    unless @client
      flash[:info] = "No encontramos al cliente."
      redirect_to distributor_clients_path and return
    end # if @client and @client.is_new #

    if params[:notification]
      notification = Notification.find(params[:notification])
      notification.update_attribute(:seen, true)
    end

    @client_city = @client.City
    @messages = @current_user.ClientMessages.where(client_id: @client.id)
                  .order(created_at: :desc).paginate(page: params[:page], per_page: 50)

    @client_image = @client.avatar_url(:mini)
    @client_username = @client.username

    @distributor_image = @current_user.avatar_url(:mini)
    @distributor_username = @current_user.username

    @create_message_url = distributor_client_messages_path(@client)
  end

  def create_message
    region_ids = @current_user.Regions.map(&:id)
    @client = Client.where(city_id: region_ids).where(hash_id: params[:id]).take

    unless @client
      flash[:info] = "No encontramos a tu cliente."
      redirect_to distributor_clients_path and return
    end # if @client and @client.is_new #

    message = ClientDistributorComment.new(
            {client_id: @client.id, distributor_id: @current_user.id,
             comment: params[:comment], is_from_client: false})
    message.save

    Notification.create(client_id: @client.id, icon: "fa fa-comments-o",
                    description: "El distribuidor respondió a tu mensaje",
                    url: client_my_distributor_path)

    flash[:success] = "Mensaje guardado."
    redirect_to distributor_client_messages_path(@client.hash_id)
  end
end
