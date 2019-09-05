class Api::OrdersController < ApiController
  before_action do
    authenticate_user!(Client)
  end

  def index
    orders = @current_user.Orders.where.not(state: "ORDER_CANCELED")
    .order(created_at: :desc).paginate(page: params[:page], per_page: 10)
    .includes(City: :State)
    data = [{per_page: 10}]
    orders.each do |order|
      extra_data = {hash_id: order.hash_id, date: I18n.l(order.created_at, format: :long),
        total: order.total, status: I18n.t(order.state), tracking_code: order.tracking_code, guides: order.json_guides,
        payment_method: order.payment_method, download_payment_key: order.download_payment_key,
        shipping_cost: order.shipping_cost}

      data << extra_data
    end

    render status: 200, json: {success: true, info: "DATA_RETURNED", data: data}
  end

  def show
    if !params[:notification].blank?
      notification = Notification.find(params[:notification])
      notification.update_attributes(seen: true)
    end

    order = @current_user.Orders.where(hash_id: params[:id]).take
    render status: 200, json: {success: false, info: "ORDER_NOT_FOUND"} and return unless order

    warehouse = order.Warehouse
    details = order.Details
    fiscal_data = @current_user.FiscalData

    data = Hash.new
    data[:shipping_cost] = order.shipping_cost
    data[:cancel_description] = order.cancel_description
    data[:reject_description] = order.reject_description

    city = warehouse.City
    warehouse_data = {address: warehouse.address, city: city.name,
      state: city.State.name, lada: city.lada, telephone: warehouse.telephone }

    data[:warehouse_data] = warehouse_data
    data[:fiscal_data] = fiscal_data
    if !fiscal_data.blank?
      data[:fiscal_data_city_name] = fiscal_data.City.name
      data[:fiscal_data_state_name] = fiscal_data.City.State.name
    end

    details_data = Array.new
    details.each do |detail|
      product = detail.Product
      details_data << {product: product.name, presentation: product.presentation,
        product_unit_price: detail.price, quantity: detail.quantity, iva: detail.iva, ieps: detail.ieps,
        total_iva: detail.total_iva, total_ieps: detail.total_ieps}
    end
    data[:order_details] = details_data

    render status: 200, json: {success: true, info: "DATA_RETURNED", data: data}
  end

  def create
    if @current_user.street.nil?
      render status: 200, json: {success: false, info: "CLIENT_DATA_NOT_COMPLETE"} and return
    end
    order = setBasicInfo()

    products = WarehouseProduct.where(hash_id: params[:product_details].keys)
      .where(describes_total_stock: true).includes(:Product)
    order.warehouse_id = products[0].warehouse_id

    custom_prices = @current_user.ProductPrices.where(product_id: products.map(&:product_id))
    products.each do |p|
      detail = OrderDetail.for(custom_prices, p, params[:product_details])
      order.total += detail.sub_total
      order.Details << detail
    end

    begin
      ActiveRecord::Base.transaction do
        order.save!
        products.each {|p| p.withdraw(params[:product_details][p.hash_id].to_i)}
        order.create_conekta_charge(@current_user, products, custom_prices) if order.payment_method_code == "OXXO_PAY"
        if order.payment_method_code == "BBVA"
          response = order.create_bbva_charge(@current_user, order)
          order.update_attributes!(bbva_charge_id: response["id"])
          render status: 200, json:{ success: true, info: "BBVA_SAVED", 
            redirect_to: response["payment_method"]["url"] }
          return
        end
      end # transaction
    rescue ActiveRecord::RecordInvalid
      render status: 200, json: { success: false, info: "SAVE_ERROR" } and return
    rescue ActiveRecord::RangeError
      render status: 200, json: { success: false, info: "NO_ENOUGH_STOCK" } and return
    rescue BbvaTransactionException
      render status: 200, json: { success: false, info: "SAVE_ERROR_BBVA_1020" } and return
    rescue Conekta::ParameterValidationError => error
      logger.error "<<< message: #{error.message}"
      logger.error error.backtrace.join("\n")
      render status: 200, json: { success: false, info: "SAVE_ERROR_CONEKTA_1010" } and return
    end # begin

    SendOrderConfirmationJob.perform_later(@current_user, order)
    render status: 200, json: { success: true, info: "SAVED" }
  end

  def cancel
    order = @current_user.Orders.where(hash_id: params[:id]).take
    unless ["WAITING_FOR_PAYMENT", "LOCAL"].include? order.state
      render status: 200, json: {success: false, info: "NOT_ELIGIBLE"}
      return
    end
    details = OrderDetail.where(order_id: order.id)

    ActiveRecord::Base.transaction do
      details.each {|d| WarehouseProduct.return(d.w_product_id, d.quantity)}

      if order.update(state: "ORDER_CANCELED")
        render status: 200, json: {success: true, info: "SAVED"}
      else
        render status: 200, json: {success: false, info: "SAVE_ERROR"}
      end
    end
  end

  def upload_payment
    render status: 200, json: {success: false, info: "PAYMENT_NOT_FOUND"} and return unless params[:payment]
    valid_states = %w(WAITING_FOR_PAYMENT PAYMENT_DEPOSITED PAYMENT_REJECTED LOCAL)

    order = Order.find_by!(hash_id: params[:id])
    render_404 and return unless valid_states.include? order.state

    order.payment = params[:payment]
    order.state = "PAYMENT_DEPOSITED"
    order.download_payment_key = SecureRandom.urlsafe_base64

    render status: 200, json: {success: true, info: "SAVED"} and return if order.save
    render status: 200, json: {success: false, info: "SAVE_ERROR"}
  end

  def available_banks
    banks = Bank.all.includes(:Accounts)
    data = Array.new

    banks.each do |bank|
      account = bank.Accounts[0]
      extra_data = {bank_name: bank.name, image_url: bank.image.url(:mini), id: bank.id,
        account: {bank_name: bank.name, account_number: account.account_number, 
          interbank_clabe: account.interbank_clabe, owner: account.owner, 
          email: account.email, RFC: account.RFC}}
      data << extra_data
    end

    render status: 200, json: {success: true, info: "DATA_RETURNED", data: data}
  end

  def update_payment_method
    render_404 and return if params[:payment_method].nil?
    order = @current_user.Orders.find_by!(hash_id: params[:id])

    ActiveRecord::Base.transaction do
      order.update_attributes(payment_method: params[:payment_method])
      if order.payment_method_code == "OXXO_PAY"
        break if order.conekta_order_id.present?

        order_details = order.Details
        products = WarehouseProduct.where(id: order_details.map{ |detail| detail.w_product_id })
          .where(describes_total_stock: true).includes(:Product)
        custom_prices = @current_user.ProductPrices.where(product_id: products.map(&:product_id))

        order.create_conekta_charge(@current_user, products, custom_prices)
      end
    end

    render status: 200, json: {success: true, info: "SAVED"}
  end

  def download_payment
    order = Order.find_by!(download_payment_key: params[:payment_key])
    render_404 and return unless order.payment.present?

    send_file order.payment.path
  end

  def sr_parcel_prices
    cart_weight = params["total_weight"];
    boxes_selected, available_boxes = Box.selectByWeight(cart_weight)
    
    parcels = Hash.new
    boxes_selected.keys.each do |key|
      box = available_boxes.select{|box| box["name"] == key }[0] # get the box obj
      jsonArray = Box.fetchSrQuotations(@current_user.cp, box) # get Quotations from Sr Envío
      no_boxes = boxes_selected[key]

      jsonArray.each do |obj| # build up parcels json
        key = "#{obj['provider']}_#{obj['service_level_code']}"
        parcels[key] = obj unless parcels[key].present?

        if parcels[key] and parcels[key]["grand_total"].present?
          parcels[key]["grand_total"] += obj["total_pricing"].to_f * no_boxes
        else
          parcels[key]["grand_total"] = obj["total_pricing"].to_f * no_boxes
        end # end if "grand_total"
      end # end jsonArray.each
    end # end boxes_selected.keys.each

    render status: 200, json: {success: true, info: "PARCELS_RETURNED",
      parcels: parcels, boxes_selected: boxes_selected, local: Local.forLocation(@current_user.city_id)}
  end

  def oxxo_pay_stub
    order = @current_user.Orders.where(hash_id: params[:id]).take
    render_404 and return unless order.payment_method_code == "OXXO_PAY"

    require "conekta"
    Conekta.api_key = Order.conekta_api_key()
    Conekta.api_version = "2.0.0"
    conekta_order = Conekta::Order.find(order.conekta_order_id)

    render status: 200, json:{
      success: true, info: "ORDER_DATA_RETURNED", data: conekta_order
    }
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
      render status: 200, json: { success: true, info: "PAYMENT_COMPLETED" }
    when "expired"
      order.cancel!("Fecha límite de pago alcanzada")
      render status: 200, json: { success: false, info: "PAYMENT_EXPIRED", order_id: order.hash_id }
    when "charge_pending"
      render status: 200, json: {
        success: true, info: "REDIRECTING_TO_BBVA", 
        redirect_to: charge["payment_method"]["url"]
      }
    else
      render_404
    end
  end

  private
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
      order.invoice_payment = params[:invoice_payment_method] if params[:invoice] == "1"

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
