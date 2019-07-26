class Distributor::OrdersController < ApplicationController
  before_action -> { current_user_is_a?(Distributor) }
  layout "distributor_layout.html.erb"

  def index
    if params[:client]
      @client = Client.find_by!(hash_id: params[:client])
      @client_city = @client.City
      @orders = Order.where(client_id: @client.id).order(updated_at: :desc).limit(100)
        .paginate(page: params[:page], per_page: 20).includes(City: :State)
      @current_user.updateRevision(@client)
    else
      @orders = @current_user.Orders.order(updated_at: :desc).limit(150)
        .paginate(page: params[:page], per_page: 20).includes(City: :State).includes(:Client)
    end
  end

  def details
    require "barby"
    require "barby/barcode/code_128"
    require "barby/outputter/png_outputter"

    @order = Order.find_by!(hash_id: params[:id])
    @order_address = @order.address_hash

    @details = @order.Details.includes(:Product)
    @client = @order.Client
    @fiscal_data = @client.FiscalData
    if @fiscal_data
      @city = @fiscal_data.City
      @state = @city.State
    end

    @client_city = @current_user.City
    @client_state = State.where(id: @client_city.state_id).take

    @barcode = Barby::Code128.new(@order.hash_id).to_image.to_data_url

    render "shared/orders/details", layout: false
  end
end
