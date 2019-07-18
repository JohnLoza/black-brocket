class Api::OrdersController < ApiController
  before_action do
    authenticate_user!(Client)
  end

  def index
    orders = @current_user.Orders.where.not(state: "ORDER_CANCELED")
    .order(created_at: :desc).paginate(page: params[:page], per_page: 10)
    .includes(City: :State)
    data = Array.new
    data << {per_page: 10}
    orders.each do |order|
      begin
        guides = JSON.parse order.guides
      rescue
        guides = Hash.new
      end

      extra_data = {hash_id: order.hash_id, date: I18n.l(order.created_at, format: :long),
        total: order.total, status: I18n.t(order.state), tracking_code: order.tracking_code, guides: guides,
        payment_method: order.payment_method, download_payment_key: order.download_payment_key,
        shipping_cost: order.shipping_cost}

      data << extra_data
    end

    render status: 200, json: {success: true, info: "DATA_RETURNED", data: data}
  end

  def payment_steps
    data = Hash.new
    data[:step1]="Realice el pago total de su compra a una de las siguientes cuentas."
    data[:step2]="Tome una foto, escanee o guarde el archivo del comprobante de pago."
    data[:step3]="Seleccione el comprobante de pago dando click en \“Enviar comprobante de pago\”"
    data[:note]="Si por error eligió un archivo equivocado y desea enviar otro, solo de click nuevamente en \“Enviar comprobante de pago\” y seleccione el correcto."

    order = @current_user.Orders.find_by!(hash_id: params[:id])
    bank = Bank.find_by!(id: order.payment_method)
    bank_accounts = bank.Accounts

    extra_data = Array.new
    bank_accounts.each do |account|
      extra_data << {bank_name: bank.name, account_number: account.account_number, 
        interbank_clabe: account.interbank_clabe, owner: account.owner, 
        email: account.email, RFC: account.RFC}
    end

    data[:bank_data] = extra_data
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
    if params[:invoice]=="1" and @current_user.FiscalData.nil?
      render status: 200, json: {success: false, info: "FISCAL_DATA_NOT_FOUND"} and return
    end
    order = setBasicInfo()
    # find the products the client want to buy #
    products = WarehouseProduct.where(hash_id: params[:product_details].keys)
      .where(describes_total_stock: true).includes(:Product)

    order.warehouse_id = products[0].warehouse_id
    unless WarehouseProduct.enoughStock?(products, params[:product_details])
      render status: 200, json: {success: false, info: "NO_ENOUGH_EXISTENCE", 
        data: {product: product.hash_id, existence: product.existence} } and return
    end

    # get the corresponding prices and create the details of the order #
    total = 0
    products.each do |p|
      detail = OrderDetail.for(@current_user, products, p, params[:product_details])
      total += detail.sub_total
      order.Details << detail
    end

    # finally save all the stuff to the database #
    ActiveRecord::Base.transaction do
      order.total = total + params[:delivery_cost].to_f
      begin
        order.save!
        products.each {|p| p.withdraw(session[:e_cart][p.hash_id].to_i)}
      rescue ActiveRecord::RecordInvalid
        render status: 200, json: {success: false, info: "SAVE_ERROR"} and return
      rescue
        render status: 200, json: {success: false, info: "NO_ENOUGH_STOCK"} and return
      end
      render status: 200, json: {success: true, info: "SAVED"} and return
    end
    # TODO add action to history file

    render status: 200, json: {success: false, info: "SAVE_ERROR"} and return
  end

  def cancel
    order = @current_user.Orders.where(hash_id: params[:id]).take
    details = OrderDetail.where(order_id: order.id)

    ActiveRecord::Base.transaction do
      details.each {|d| WarehouseProduct.restock(d.w_product_id, d.quantity)}

      if order.update(state: "ORDER_CANCELED")
        render status: 200, json: {success: true, info: "SAVED"}
        # TODO add action to history file
      else
        render status: 200, json: {success: false, info: "SAVE_ERROR"}
      end
    end
  end

  def upload_payment
    render status: 200, json: {success: false, info: "PAYMENT_NOT_FOUND"} and return unless params[:payment]
    order = @current_user.Orders.find_by!(hash_id: params[:id])

    if params[:payment].content_type.include? "pdf"
      order.remove_pay_img! if !order.pay_img.blank?
      order.pay_pdf = params[:payment]
    elsif params[:payment].content_type.include? "image"
      order.remove_pay_pdf! if !order.pay_pdf.blank?
      order.pay_img = params[:payment]
    else
      render status: 200, json: {success: false, info: "FILE_FORMAT_ERROR"} and return
    end
    order.state = "PAYMENT_DEPOSITED"
    order.download_payment_key = SecureRandom.urlsafe_base64 if order.download_payment_key.nil?

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

    order.update_attributes(payment_method: params[:payment_method])

    render status: 200, json: {success: true, info: "SAVED"}
  end

  def download_payment
    order = Order.find_by!(download_payment_key: params[:payment_key])

    if order.pay_img.present?
      send_file order.pay_img.path
    elsif order.pay_pdf.present?
      send_file order.pay_pdf.path
    end
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

  private
    def setBasicInfo
      order = Order.new
      order.hash_id = Utils.new_alphanumeric_token(9).upcase
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
      return order
    end
end
