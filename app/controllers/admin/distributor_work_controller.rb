class Admin::DistributorWorkController < AdminController

  def index
    deny_access! and return unless @current_user.has_permission_category?('distributor_work')

    @clients = Client.joins(:City).where(cities: {distributor_id: nil})
            .where(worker_id: nil).includes(City: :State)
            .paginate(page: params[:page], per_page: 25)
  end

  def take_client
    deny_access! and return unless @current_user.has_permission_category?('distributor_work')

    client = Client.find_by!(hash_id: params[:id])
    deny_access! and return unless client.worker_id.nil?
    client.update_attribute(:worker_id, @current_user.id)

    flash[:success] = "Cliente añadido a tu repertorio."
    redirect_to admin_distributor_work_clients_path
  end

  def my_clients
    deny_access! and return unless @current_user.has_permission_category?('distributor_work')

    @clients = @current_user.Clients
  end

  def prices
    deny_access! and return unless @current_user.has_permission_category?('distributor_work')

    @client = Client.find_by!(hash_id: params[:id])

    @product_prices = @client.ProductPrices
    @client_city = @client.City
    @products = Product.where(deleted_at: nil).order(name: :asc)
  end

  def create_prices
    deny_access! and return unless @current_user.has_permission_category?('distributor_work')
    @client = Client.find_by!(hash_id: params[:id])

    ActiveRecord::Base.transaction do
      @client.ProductPrices.delete_all
      params[:product].each do |product_id|
        ClientProduct.create(client_id: @client.id, product_id: product_id, client_price: params[:product][product_id])
      end

      @client.update_attributes(has_custom_prices: true, is_new: false)
      flash[:success] = "Precios de #{@client.full_name} actualizados"
    end

    flash[:info] = "Ocurrió un error al actualizar los precios" unless flash[:success].present?
    redirect_to admin_distributor_work_my_clients_path
  end

  def messages
    deny_access! and return unless @current_user.has_permission_category?('distributor_work')
    @client = Client.find_by!(hash_id: params[:id])

    if params[:notification]
      notification = Notification.find(params[:notification])
      notification.update_attribute(:seen, true)
    end

    @client_city = @client.City
    @messages = @current_user.ClientMessages.where(client_id: @client.id)
                  .order(created_at: :desc).paginate(page: params[:page], per_page: 25)

    @client_image = @client.avatar_url(:mini)
    @client_username = @client.username

    @distributor_image = @current_user.avatar_url(:mini)
    @distributor_username = @current_user.username

    @create_message_url = admin_distributor_work_client_messages_path(@client.hash_id)
  end

  def create_message
    deny_access! and return unless @current_user.has_permission_category?('distributor_work')
    @client = Client.find_by!(hash_id: params[:id])

    ActiveRecord::Base.transaction do
      ClientDistributorComment.create(client_id: @client.id,
        worker_id: @current_user.id, comment: params[:comment], is_from_client: false)

      Notification.create(client_id: @client.id, icon: "fa fa-comments-o",
        description: "El distribuidor respondió a tu mensaje", url: client_my_distributor_path)
      flash[:success] = "Mensaje guardado."
    end

    flash[:info] = "Ocurrió un error al guardar el mensaje" unless flash[:success].present?
    redirect_to admin_distributor_work_client_messages_path(@client.hash_id)
  end

  def orders
    deny_access! and return unless @current_user.has_permission_category?('distributor_work')

    @orders = Order.joins(:Client).where(clients: {worker_id: @current_user.id})
              .order(created_at: :desc).paginate(page: params[:page], per_page: 20)
  end

end
