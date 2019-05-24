class Client::OrdersController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_client?
  before_action :verify_fiscal_data, only: [:create]

  def index
    @orders = @current_user.Orders.where.not(state: "ORDER_CANCELED").order(created_at: :desc).paginate(page: params[:page], per_page: 10).includes(City: :State)
    @bank_accounts = BankAccount.all
  end

  def show
    if params[:notification]
      notification = Notification.find(params[:notification])
      notification.update_attribute(:seen, true)
    end
    @order = Order.find_by!(hash_id: params[:id])
    @order_address = @order.address_hash

    @details = @order.Details.includes(:Product)
    @client = @order.Client
    @fiscal_data = @client.FiscalData
    if !@fiscal_data.blank?
      @city = @fiscal_data.City
      @state = @city.State
    end

    @client_city = @current_user.City
    @client_state = State.where(id: @client_city.state_id).take

    render "/shared/orders/details", layout: false
  end

  def create
    return unless verify_client_address
    return unless verify_fiscal_data
    @order = setBasicInfo

    # find the products the client want to buy and verify stock #
    @products = WarehouseProduct.where(hash_id: session[:e_cart].keys)
      .where(describes_total_stock: true).includes(:Product)
    @order.warehouse_id = @products[0].warehouse_id
    unless WarehouseProduct.enoughStock?(@products, session[:e_cart])
      flash[:info] = "Lo sentimos pero no queda suficiente inventario del producto #{product.Product.name} su existencia actual es de: #{product.existence}"
      redirect_to client_ecart_path(@current_user.hash_id) and return
    end

    # get the corresponding prices and create the details of the order #
    @total = 0
    @products.each do |p|
      detail = OrderDetail.for(current_user, @products, p, session[:e_cart])
      @total += detail.sub_total
      @order.Details << detail
    end # @products.each do #

    # finally save all the stuff to the database #
    ActiveRecord::Base.transaction do
      @order.total = @total + params[:delivery_cost].to_f
      begin
        @order.save!
      rescue ActiveRecord::RecordInvalid
        flash[:info] = "ocurrió un error al procesar la órden"
        redirect_to client_ecart_path(@current_user.hash_id) and return
      end
      @products.each do |p|
        p.update_attributes(existence: (p.existence - session[:e_cart][p.hash_id].to_i))
      end
      flash[:success] = "Orden guardada"
      session.delete(:e_cart)
      redirect_to client_orders_path(@current_user.hash_id) and return
    end

    flash[:info] = "Ocurrió un error al guardar tu pedido, vuelve a intentarlo por favor..."
    redirect_to client_ecart_path(@current_user.hash_id)
  end

  def cancel
    @order = @current_user.Orders.where(hash_id: params[:id]).take

    if @order and ["WAITING_FOR_PAYMENT", "LOCAL"].include? @order.state
      ActiveRecord::Base.transaction do
        @details = OrderDetail.where(order_id: @order.id)

        @details.each do |d|
          query = "UPDATE warehouse_products "+
              "SET existence=(existence+#{d.quantity}) WHERE "+
              "id="+d.w_product_id.to_s
          ActiveRecord::Base.connection.execute(query)
        end

        @order.update(state: "ORDER_CANCELED")
        @destroyed = true
      end
    else
      @destroyed = false
    end

    respond_to do |format|
      format.js{ render :cancel, layout: false }
    end
  end

  def upload_payment
    @order = Order.find_by!(hash_id: params[:id])
    if params[:order] and @order and 
      ["WAITING_FOR_PAYMENT", "PAYMENT_DEPOSITED", "PAYMENT_REJECTED"].include? @order.state
      if params[:order][:pay_img].content_type == "application/pdf"
        @order.remove_pay_img! if !@order.pay_img.blank?
        @order.pay_pdf = params[:order][:pay_img]
      else
        @order.remove_pay_pdf! if !@order.pay_pdf.blank?
        @order.pay_img = params[:order][:pay_img]
      end
      @order.state = "PAYMENT_DEPOSITED"
      @order.download_payment_key = SecureRandom.urlsafe_base64
      @saved = true if @order.save!
    end

    if @saved
      flash[:success] = "Pago guardado, esperando confirmación"
    else
      flash[:info] = "Ocurrió un error al guardar el pago, recuerda que los formatos admitidos son: pdf, jpg y png."
    end
    redirect_to client_orders_path(@current_user.hash_id)
  end

  def get_payment
    @order = @current_user.Orders.find_by!(download_payment_key: params[:id])
    # if there is an image of the payment send it
    file_path = @order.pay_img.path if @order.pay_img.present?
    # else, if there is a pdf of the payment, send it
    file_path = @order.pay_pdf.path if @order.pay_pdf.present?

    render_404 and return unless file_path

    send_file file_path
  end

  def get_bank_payment_info
    @order = @current_user.Orders.find_by!(hash_id: params[:id])
    @bank = Bank.find_by!(id: @order.payment_method)
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
      if params[:invoice]=="1" and @current_user.FiscalData.nil?
        flash[:info] = 'Llena tus datos fiscales primero por favor.'
        redirect_to new_client_fiscal_datum_path and return false
      end
      return true
    end

    def verify_client_address
      if @current_user.street.nil?
        flash[:info] = 'Por favor completa tus datos.'
        redirect_to edit_client_client_path @current_user and return false
      end
      return true
    end

    def setBasicInfo
      order = Order.new
      order.hash_id = Utils.new_alphanumeric_token(9).upcase
      order.client_id = @current_user.id
      order.city_id = @current_user.city_id
      order.distributor_id = @current_user.distributorId
      order.shipping_cost = params[:delivery_cost]
      order.guides = params[:guides]
      order.payment_method = params[:payment_method]
      order.parcel_id = params[:parcel_id]
      order.invoice = params[:invoice] if params[:invoice]
      order.state = params[:parcel_id] == '0' ? "LOCAL" : "WAITING_FOR_PAYMENT"
      address = {street: @current_user.street, extnumber: @current_user.extnumber,
        intnumber: @current_user.intnumber, col: @current_user.col,
        cp: @current_user.cp, street_ref1: @current_user.street_ref1,
        street_ref2: @current_user.street_ref2, city_id: @current_user.city_id}
      order.address = address
      return order
    end
end
