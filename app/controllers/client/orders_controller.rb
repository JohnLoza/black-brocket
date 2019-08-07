class Client::OrdersController < ApplicationController
  before_action -> { user_should_be(Client) }
  before_action :process_notification, only: :show
  before_action :verify_client_address, only: :create

  def index
    @orders = @current_user.Orders
      .where.not(state: "ORDER_CANCELED").order(created_at: :desc)
      .paginate(page: params[:page], per_page: 10).includes(City: :State)
  end

  def show
    require "barby"
    require "barby/barcode/code_128"
    require "barby/outputter/png_outputter"

    @order = Order.find_by!(hash_id: params[:id])
    
    begin
      @guides_json = JSON.parse @order.guides
    rescue
      @guides_json = nil
    end

    @order_address = @order.address_hash

    @details = @order.Details.includes(:Product)
    @client = @current_user
    @fiscal_data = @client.FiscalData

    @barcode = Barby::Code128.new(@order.hash_id).to_image.to_data_url

    render "shared/orders/details", layout: false
  end

  def create
    render_404 and return unless session[:e_cart].present?
    order = setBasicInfo

    # find the products the client want to buy and verify stock #
    products = WarehouseProduct.where(hash_id: session[:e_cart].keys)
      .where(describes_total_stock: true).includes(:Product)
    order.warehouse_id = products[0].warehouse_id

    # get the corresponding prices and create the details of the order #
    custom_prices = @current_user.ProductPrices.where(product_id: products.map(&:product_id))
    products.each do |p|
      detail = OrderDetail.for(custom_prices, p, session[:e_cart])
      order.total += detail.sub_total
      order.Details << detail
    end # products.each do #

    # finally save all the stuff to the database #
    begin
      ActiveRecord::Base.transaction do
        order.save!
        products.each {|p| p.withdraw(session[:e_cart][p.hash_id].to_i)}
      end
    rescue ActiveRecord::RecordInvalid
      flash[:info] = "ocurrió un error al procesar la órden"
    rescue ActiveRecord::RangeError
      flash[:info] = "No existe inventario suficiente"
    ensure
      if flash[:info].present?
        redirect_to client_ecart_path(current_user.hash_id) and return
      else
        flash[:success] = "Orden guardada"; session.delete(:e_cart)
        SendOrderConfirmationJob.perform_later(current_user, order)
        verify_fiscal_data or return 
        redirect_to client_orders_path(current_user.hash_id, info_for: order.hash_id) and return
      end
    end
  end

  def cancel
    @order = @current_user.Orders.find_by!(hash_id: params[:id])
    return unless ["WAITING_FOR_PAYMENT", "LOCAL"].include? @order.state
    @details = OrderDetail.where(order_id: @order.id)
    
    ActiveRecord::Base.transaction do
      # TODO add dependent destroy and trigger the return method on detail destroy
      @details.each {|d| WarehouseProduct.return(d.w_product_id, d.quantity)}
      @order.update_attributes!(state: "ORDER_CANCELED")
    end

    respond_to do |format|
      format.html{
        flash[:info] = "Órden #{@order} cancelada"
        redirect_to client_orders_path(@current_user)
      }
      format.js{ render :cancel, layout: false }
    end
  end

  def upload_payment
    render_404 and return unless params[:order] and params[:order][:payment]
    valid_states = %w(WAITING_FOR_PAYMENT PAYMENT_DEPOSITED PAYMENT_REJECTED LOCAL)

    order = Order.find_by!(hash_id: params[:id])
    render_404 and return unless valid_states.include? order.state
    
    order.payment = params[:order][:payment]
    order.state = "PAYMENT_DEPOSITED" unless order.state == "LOCAL"
    order.download_payment_key = SecureRandom.urlsafe_base64
    flash[:success] = "Pago guardado, esperando confirmación" if order.save

    flash[:info] = "Ocurrió un error al guardar el pago, recuerda que los formatos admitidos son: pdf, jpg y png." unless flash[:success].present?
    redirect_to client_orders_path(@current_user)
  end

  def get_payment
    order = @current_user.Orders.find_by!(download_payment_key: params[:id])
    render_404 and return unless order.payment.present?

    send_file order.payment.path
  end

  def get_bank_payment_info
    @order = @current_user.Orders.find_by!(hash_id: params[:id])
    render_404 and return unless @order.payment_method.present?
    
    @bank = Bank.find(@order.payment_method)
    @bank_accounts = @bank.Accounts

    respond_to do |format|
      format.js { render :get_bank_payment_info, layout: false }
    end
  end

  def update_payment_method
    return if params[:order][:payment_method].nil?
    @order = @current_user.Orders.find_by!(hash_id: params[:id])
    @order.update_attributes(payment_method: params[:order][:payment_method])

    respond_to do |format|
      format.js { render :update_payment_method, layout: false }
    end
  end

  private
    def verify_fiscal_data
      return true if params[:invoice] == "0" # doesn't require invoice

      data = @current_user.FiscalData
      return true if data.present?
      
      flash[:info] = "Por favor completa tu información fiscal (con fines de facturación)"
      redirect_to edit_client_fiscal_datum_path(@current_user.hash_id)
      return false
    end

    def verify_client_address
      if @current_user.street.nil?
        flash[:info] = "Por favor completa tus datos."
        redirect_to edit_client_client_path @current_user and return false
      end
      return true
    end

    def setBasicInfo
      order = Order.new
      order.client_id = @current_user.id
      order.city_id = @current_user.city_id
      order.distributor_id = @current_user.distributorId
      order.shipping_cost = params[:delivery_cost]
      order.guides = params[:guides]
      order.payment_method = params[:payment_method]

      order.invoice = params[:invoice] if params[:invoice]
      order.cfdi = params[:cfdi] if params[:invoice] == "1"
      order.invoice_payment = params["invoice-payment-method"] if params[:invoice] == "1"

      order.state = params[:parcel_id] == "0" ? "LOCAL" : "WAITING_FOR_PAYMENT"

      address = {street: @current_user.street, extnumber: @current_user.extnumber,
        intnumber: @current_user.intnumber, col: @current_user.col,
        cp: @current_user.cp, street_ref1: @current_user.street_ref1,
        street_ref2: @current_user.street_ref2, city_id: @current_user.city_id}
      order.address = address
      order.total = 0 + params[:delivery_cost].to_f
      return order
    end
end
