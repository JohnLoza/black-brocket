class Client::OrdersController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_client?
  before_action :verify_fiscal_data, only: [:create]

  def index
    @orders = @current_user.Orders.where.not(state: "ORDER_CANCELED").order(created_at: :desc).paginate(:page => params[:page], :per_page => 10).includes(City: :State)
    @bank_accounts = BankAccount.all
  end

  def show
    if params[:notification]
      notification = Notification.find(params[:notification])
      notification.update_attribute(:seen, true)
    end
    @order = Order.find_by(alph_key: params[:id])

    if @order
      @details = @order.Details.includes(:Product)
      @client = @order.Client
      @fiscal_data = @client.FiscalData
      if !@fiscal_data.blank?
        @city = @fiscal_data.City
        @state = @city.State
      end

      @client_city = @current_user.City
      @client_state = State.where(id: @client_city.state_id).take

      render :show, layout: false
      return
    else
      flash[:info] = "No se encontró la orden con clave: #{params[:id]}"
      redirect_to client_orders_path(@current_user.alph_key)
      return
    end
  end

  def create
    verify_fiscal_data # only if requires invoice #

    @order = Order.new

    # find the corresponding distributor #
    @order.distributor_id = 0
    @distributor = @current_user.City.Distributor
    if !@distributor.nil?
      @order.distributor_id = @distributor.id
    end

    # save some order values #
    @order.client_id = @current_user.id
    @order.city_id = @current_user.city_id
    @order.invoice = params[:invoice] if params[:invoice]
    @order.state = "WAITING_FOR_PAYMENT"

    @order.alph_key = SecureRandom.urlsafe_base64(6)

    # find the products the client want to buy #
    @products = WarehouseProduct.where(alph_key: session[:e_cart].keys)
                .where(describes_total_stock: true).includes(:Product)

    @products.each do |product|
      puts "--- existence: #{product.existence}, buying: #{session[:e_cart][product.alph_key]}"
      if product.existence < session[:e_cart][product.alph_key].to_i
        flash[:danger] = "Lo sentimos pero no queda suficiente inventario del producto con clave #{product.Product.alph_key} su existencia actual es de: #{product.existence}"
        redirect_to client_ecart_path(@current_user.alph_key)
        return
      end
    end

    product_prices = @current_user.ProductPrices.where("product_id in (?)", @products.map(&:product_id))

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

      subtotal = session[:e_cart][p.alph_key].to_i*current_product_price
      total+=subtotal

      total_iva = current_product_price-(current_product_price*100/(p.Product.iva+100))
      total_ieps = (current_product_price-total_iva)-((current_product_price-total_iva)*100/(p.Product.ieps+100))

      @order_details << OrderDetail.new(product_id: p.product_id,
                  alph_key: SecureRandom.urlsafe_base64(6), iva: p.Product.iva,
                  quantity: session[:e_cart][p.alph_key], sub_total: subtotal,
                  w_product_id: p.id, ieps: p.Product.ieps, price: current_product_price,
                  total_iva: total_iva * session[:e_cart][p.alph_key].to_i,
                  total_ieps: total_ieps * session[:e_cart][p.alph_key].to_i)
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
        p.update_attributes(existence: (p.existence-session[:e_cart][p.alph_key].to_i))
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
      redirect_to client_orders_path(@current_user.alph_key)
      return
    else
      flash[:danger] = "Ocurrió un error al guardar tu pedido, vuelve a intentarlo por favor..."
      redirect_to client_ecart_path(@current_user.alph_key)
    end
  end

  def cancel
    @order = @current_user.Orders.where(alph_key: params[:id]).take

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
    @order = Order.where(alph_key: params[:id]).take
    if params[:order] and @order
        if params[:order][:pay_photo].content_type == "application/pdf"
          @order.remove_pay_photo! if !@order.pay_photo.blank?
          @saved = true if @order.update_attributes(pay_pdf: params[:order][:pay_photo], state: "PAYMENT_DEPOSITED")
        else
          @order.remove_pay_pdf! if !@order.pay_pdf.blank?
          @saved = true if @order.update_attributes(pay_photo: params[:order][:pay_photo], state: "PAYMENT_DEPOSITED")
        end
    end

    if @saved
      flash[:success] = "Pago guardado, esperando confirmación"
    else
      flash[:danger] = "Ocurrió un error al guardar el pago, recuerda que los formatos admitidos son: pdf, jpg y png."
    end
    redirect_to client_orders_path(@current_user.alph_key)
  end

  def update_order_address

  end

  private
    def verify_fiscal_data
      if params[:invoice]=="1" and @current_user.FiscalData.nil?
        flash[:danger] = 'Llena tus datos fiscales primero por favor.'
        redirect_to new_client_fiscal_datum_path
        return
      end
    end
end
