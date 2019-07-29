class Distributor::ClientsController < ApplicationController
  before_action -> { user_should_be(Distributor) }
  before_action :process_notification, only: :messages
  layout "distributor_layout.html.erb"

  def index
    region_ids = @current_user.Regions.map(&:id)
    @clients = Client.where(city_id: region_ids).order(updated_at: :DESC)
      .paginate(page: params[:page], per_page: 20).includes(City: :State)
  end

  def show
    region_ids = @current_user.Regions.map(&:id)
    @client = Client.find_by!(hash_id: params[:id], city_id: region_ids)
  end

  def prices
    region_ids = @current_user.Regions.map(&:id)
    @client = Client.find_by!(hash_id: params[:id], city_id: region_ids)

    @product_prices = @client.ProductPrices
    @client_city = @client.City
    @products = Product.active.order(name: :asc)

    @current_user.updateRevision(@client)
  end

  def create_prices
    @client = Client.find_by!(hash_id: params[:id])
    ActiveRecord::Base.transaction do
      @client.ProductPrices.destroy_all
      @client.update_attributes!(has_custom_prices: true, is_new: false)
      params[:product].each do |product_id|
        ClientProduct.create!(client_id: @client.id, product_id: product_id, client_price: params[:product][product_id])
      end
    end
    flash[:success] = "Precios guardados"
  rescue
    flash[:info] = "Ocurrió un error al guardarlos precios"
  ensure
    redirect_to distributor_clients_path
  end

  def messages
    region_ids = @current_user.Regions.map(&:id)
    @client = Client.find_by!(hash_id: params[:id], city_id: region_ids)

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
    @client = Client.find_by!(hash_id: params[:id], city_id: region_ids)

    @message = ClientDistributorComment.create({client_id: @client.id, 
      distributor_id: @current_user.id, comment: params[:comment], is_from_client: false})

    Notification.create(client_id: @client.id, icon: "fa fa-comments-o",
      description: "El distribuidor respondió a tu mensaje", url: client_my_distributor_path)

    @distributor_image = @current_user.avatar_url(:mini)
    @distributor_username = @current_user.username

    respond_to do |format|
      format.js { render :create_message, layout: false }
    end
  end
end
