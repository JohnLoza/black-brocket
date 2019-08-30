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
    order = setBasicInfo()

    products = WarehouseProduct.where(hash_id: session[:e_cart].keys)
      .where(describes_total_stock: true).includes(:Product)
    order.warehouse_id = products[0].warehouse_id

    custom_prices = @current_user.ProductPrices.where(product_id: products.map(&:product_id))
    products.each do |p|
      detail = OrderDetail.for(custom_prices, p, session[:e_cart])
      order.total += detail.sub_total
      order.Details << detail
    end # products.each do #

    begin
      ActiveRecord::Base.transaction do
        order.save!
        products.each {|p| p.withdraw(session[:e_cart][p.hash_id].to_i)}
        order.create_conekta_charge(@current_user, products, custom_prices) if order.payment_method_code == "OXXO_PAY"
        if order.payment_method_code == "BBVA"
          response = order.create_bbva_charge(@current_user, order)
          order.update_attributes!(bbva_charge_id: response["id"])
          session.delete(:e_cart)
          redirect_to response["payment_method"]["url"]
        end
      end # transaction
    rescue ActiveRecord::RecordInvalid
      flash[:info] = "Ocurrió un error al procesar la órden"
    rescue ActiveRecord::RangeError
      flash[:info] = "No existe inventario suficiente"
    rescue BbvaTransactionException
      flash[:info] = "Ocurrió un error al procesar la órden (BbvaError 1020)"
    rescue Conekta::ParameterValidationError => error
      flash[:info] = "Ocurrió un error al procesar la órden (ConektaError 1010)"
      logger.error "<<< message: #{error.message}"
      logger.error error.backtrace.join("\n")
    end # begin

    return if performed?
    if flash[:info].present?
      redirect_to client_ecart_path(current_user.hash_id) and return
    else
      flash[:success] = "Orden guardada"; session.delete(:e_cart)
      SendOrderConfirmationJob.perform_later(current_user, order)
      verify_fiscal_data or return 
      redirect_to client_orders_path(current_user.hash_id, info_for: order.hash_id) and return
    end # if flash[:info].present?
  end

  def cancel
    @order = @current_user.Orders.find_by!(hash_id: params[:id])
    return unless ["WAITING_FOR_PAYMENT", "LOCAL"].include? @order.state
    @order.cancel!

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

    payment = params[:order][:payment]
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    extension = payment.content_type.split('/')[1]
    payment.original_filename = "#{timestamp}.#{extension}"
    
    order.payment = params[:order][:payment]
    order.state = "PAYMENT_DEPOSITED" unless order.state == "LOCAL"
    order.download_payment_key = SecureRandom.urlsafe_base64 unless order.download_payment_key.present?
    order.save

    render status: 200, json: { success: order.valid? }
  end

  def get_payment
    order = @current_user.Orders.find_by!(download_payment_key: params[:id])
    render_404 and return unless order.payment.present?

    send_file order.payment.path
  end

  def get_bank_payment_info
    @order = @current_user.Orders.find_by!(hash_id: params[:id])
    return unless @order.payment_method.present?
    
    if @order.payment_method_code == "OXXO_PAY"
      require "conekta"
      Conekta.api_key = Order.conekta_api_key()
      Conekta.api_version = "2.0.0"
      @conekta_order = Conekta::Order.find(@order.conekta_order_id)
    else
      @bank = Bank.find(@order.payment_method)
      @bank_accounts = @bank.Accounts
    end

    respond_to do |format|
      format.js { render :get_bank_payment_info, layout: false }
    end
  end

  def update_payment_method
    return if params[:order][:payment_method].nil?
    @order = @current_user.Orders.find_by!(hash_id: params[:id])

    ActiveRecord::Base.transaction do
      @order.update_attributes!(payment_method: params[:order][:payment_method])

      if @order.payment_method_code == "OXXO_PAY"
        break if @order.conekta_order_id.present?

        order_details = @order.Details
        products = WarehouseProduct.where(id: order_details.map{ |detail| detail.w_product_id })
          .where(describes_total_stock: true).includes(:Product)
        custom_prices = @current_user.ProductPrices.where(product_id: products.map(&:product_id))

        @order.create_conekta_charge(@current_user, products, custom_prices)
      elsif @order.payment_method_code == "BBVA"
        break if @order.bbva_charge_id.present?

        response = @order.create_bbva_charge(@current_user, @order)
        @order.update_attributes!(bbva_charge_id: response["id"])
        @redirect_to = response["payment_method"]["url"]
      end
    end

    respond_to do |format|
      format.js { render :update_payment_method, layout: false }
    end
  end

  def pay_through_bbva
    order = @current_user.Orders.find_by!(hash_id: params[:id])
    render_404 and return unless order.payment_method_code == "BBVA"

    bbva = order.bbva_instance
    charges = bbva.create(:charges)
    begin
      charge = charges.get(order.bbva_charge_id)
    rescue BbvaTransactionException
      render_404 and return
    end
    
    case charge["status"]
    when "completed"
      redirect_to client_orders_path(@current_user), 
        flash: {success: "Ya has completado tu pago, estamos en proceso de su validacón" }
    when "expired"
      order.cancel!("Fecha límite de pago alcanzada")
      redirect_to client_orders_path(@current_user),
        flash: {info: "Fecha límite de pago alcanzada para la órden #{order.hash_id}"}
    when "charge_pending"
      redirect_to charge["payment_method"]["url"]
    else
      render_404
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
