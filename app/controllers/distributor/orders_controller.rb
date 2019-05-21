class Distributor::OrdersController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_distributor?
  layout "distributor_layout.html.erb"

  def index
    if params[:client]
      @client = Client.find_by!(hash_id: params[:client])
      if @client
        @client_city = @client.City
        @orders = Order.where(client_id: @client.id).order(updated_at: :desc).limit(100).paginate(:page => params[:page], :per_page => 10).includes(City: :State)

        @current_user.updateRevision(@client)
      else
        flash[:info]="No encontramos al cliente."
        redirect_to distributor_clients_path and return
      end
    else
      @orders = @current_user.Orders.order(updated_at: :desc).limit(150).paginate(:page => params[:page], :per_page => 10).includes(City: :State).includes(:Client)
    end
  end

  def details
    @order = Order.find_by!(hash_id: params[:id])
    unless @order
      flash[:info] = "No se encontró la orden con clave: #{params[:id]}"
      redirect_to distributor_orders_path and return
    end

    @details = @order.Details.includes(:Product)
    @client = @order.Client
    @fiscal_data = @client.FiscalData
    if @fiscal_data
      @city = @fiscal_data.City
      @state = @city.State
    end

    @client_city = @current_user.City
    @client_state = State.where(id: @client_city.state_id).take

    render :details, layout: false
  end
end
