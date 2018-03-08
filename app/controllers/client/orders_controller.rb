class Client::OrdersController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_client?
  before_action :verify_fiscal_data, only: [:create]

  def index
    @orders = current_user.Orders.where.not(state: "ORDER_CANCELED").order(created_at: :desc).paginate(:page => params[:page], :per_page => 10).includes(City: :State)
    @bank_accounts = BankAccount.all
  end

  def show
    if params[:notification]
      notification = Notification.find(params[:notification])
      notification.update_attribute(:seen, true)
    end
    @order = Order.find_by(hash_id: params[:id])

    if @order
      @details = @order.Details.includes(:Product)
      @client = @order.Client
      @fiscal_data = @client.FiscalData
      if !@fiscal_data.blank?
        @city = @fiscal_data.City
        @state = @city.State
      end

      @client_city = current_user.City
      @client_state = State.where(id: @client_city.state_id).take

      render :show, layout: false
      return
    else
      flash[:info] = "No se encontró la orden con clave: #{params[:id]}"
      redirect_to client_orders_path(current_user.hash_id)
      return
    end
  end

  def create
    verify_fiscal_data # only if requires invoice #
    @order = Order.new

    # find the corresponding distributor #
    @order.distributor_id = 0
    @distributor = current_user.City.Distributor
    if !@distributor.nil?
      @order.distributor_id = @distributor.id
    end

    # save some order values #
    @order.client_id = current_user.id
    @order.city_id = current_user.city_id
    @order.invoice = params[:invoice] if params[:invoice]
    @order.payment_method = params[:payment_method]
    @order.state = "WAITING_FOR_PAYMENT"

    @order.hash_id = random_hash_id(12).upcase

    # find the products the client want to buy #
    @products = WarehouseProduct.where(hash_id: session[:e_cart].keys)
                .where(describes_total_stock: true).includes(:Product)

    @products.each do |product|
      # puts "--- existence: #{product.existence}, buying: #{session[:e_cart][product.hash_id]}"
      if product.existence < session[:e_cart][product.hash_id].to_i
        flash[:danger] = "Lo sentimos pero no queda suficiente inventario del producto con clave #{product.Product.hash_id} su existencia actual es de: #{product.existence}"
        redirect_to client_ecart_path(current_user.hash_id)
        return
      end
    end

    product_prices = current_user.ProductPrices.where("product_id in (?)", @products.map(&:product_id))

    # get the warehouse he belogs to #
    @warehouse = @products[0].Warehouse
    @order.warehouse_id = @warehouse.id

    # get the corresponding prices and create the details of the order #
    @order_details = Array.new
    total = 0
    current_product_price = 0
    @products.each do |p|
      subtotal = 0
      if product_prices.any?
        product_prices.each do |pp|
          if pp.product_id == p.Product.id
            current_product_price = pp.client_price
            break
          end # if pp.product_id == p.Product.id #
        end # product_prices.each #
      else
        current_product_price = p.Product.price
      end # if product_prices.any? #

      subtotal = session[:e_cart][p.hash_id].to_i*current_product_price
      total+=subtotal

      total_iva = current_product_price-(current_product_price*100/(p.Product.iva+100))
      total_ieps = (current_product_price-total_iva)-((current_product_price-total_iva)*100/(p.Product.ieps+100))

      @order_details << OrderDetail.new(product_id: p.product_id,
                  hash_id: random_hash_id(12).upcase, iva: p.Product.iva,
                  quantity: session[:e_cart][p.hash_id], sub_total: subtotal,
                  w_product_id: p.id, ieps: p.Product.ieps, price: current_product_price,
                  total_iva: total_iva * session[:e_cart][p.hash_id].to_i,
                  total_ieps: total_ieps * session[:e_cart][p.hash_id].to_i)
    end # @products.each do #

    shipping_cost = 0.0
    if total < @warehouse.wholesale
      total = total + @warehouse.shipping_cost
      shipping_cost = @warehouse.shipping_cost
    end
    @order.total = total
    @order.shipping_cost = shipping_cost

    # finally save all the stuff to the database #
    @saved = false
    ActiveRecord::Base.transaction do
      @order.save
      @products.each do |p|
        p.update_attributes(existence: (p.existence-session[:e_cart][p.hash_id].to_i))
      end
      @order_details.each do |detail|
        detail.order_id = @order.id
        detail.save
      end
      @saved = true
    end

    if @saved == true
      session.delete(:e_cart)
      flash[:success] = "Orden guardada"
      redirect_to client_orders_path(current_user.hash_id)
      return
    else
      flash[:danger] = "Ocurrió un error al guardar tu pedido, vuelve a intentarlo por favor..."
      redirect_to client_ecart_path(current_user.hash_id)
    end
  end

  def cancel
    @order = current_user.Orders.where(hash_id: params[:id]).take

    if !@order.blank?
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
    @order = Order.where(hash_id: params[:id]).take
    if params[:order] and @order
        if params[:order][:pay_img].content_type == "application/pdf"
          @order.remove_pay_img! if !@order.pay_img.blank?
          @order.pay_pdf = params[:order][:pay_img]
        else
          @order.remove_pay_pdf! if !@order.pay_pdf.blank?
          @order.pay_img = params[:order][:pay_img]
        end
        @order.state = "PAYMENT_DEPOSITED"
        @order.download_payment_key = SecureRandom.urlsafe_base64 if @order.download_payment_key.nil?
        @saved = true if @order.save!
    end

    if @saved
      flash[:success] = "Pago guardado, esperando confirmación"
    else
      flash[:danger] = "Ocurrió un error al guardar el pago, recuerda que los formatos admitidos son: pdf, jpg y png."
    end
    redirect_to client_orders_path(current_user.hash_id)
  end

  def get_payment
    @order = current_user.Orders.find_by(download_payment_key: params[:id])
    if !@order.nil?
      # if there is an image of the payment send it
      if !@order.pay_img.blank?
        send_file @order.pay_img.path
      # else, if there is a pdf of the payment, send it
      elsif !@order.pay_pdf.blank?
        send_file @order.pay_pdf.path
      end
    end
  end

  def get_bank_payment_info
    @order = current_user.Orders.find_by(hash_id: params[:id])
    @bank = Bank.find_by(id: @order.payment_method) if @order
    @bank_accounts = @bank.Accounts if @bank

    respond_to do |format|
      format.js { render :get_bank_payment_info, :layout => false }
    end
  end

  def update_payment_method
    return if params[:order][:payment_method].nil?
    @order = current_user.Orders.find_by(hash_id: params[:id])

    if @order
      @order.update_attributes(payment_method: params[:order][:payment_method])
    end

    respond_to do |format|
      format.js { render :update_payment_method, :layout => false }
    end
  end

  private
    def verify_fiscal_data
      if params[:invoice]=="1" and current_user.FiscalData.nil?
        flash[:danger] = 'Llena tus datos fiscales primero por favor.'
        redirect_to new_client_fiscal_datum_path
        return
      end
    end
end
