class Api::OrdersController < ApiController
  @@user_type = :client

  def index
    orders = @current_user.Orders.where.not(state: "ORDER_CANCELED").order(created_at: :desc).paginate(:page => params[:page], :per_page => 10).includes(City: :State)
    data = Array.new
    data<<{per_page: 10}
    orders.each do |order|

      if !order.parcel_id.blank?
        extra_data = {hash_id: order.hash_id, date: l(order.created_at, format: :long),
          total: order.total, status: t(order.state), tracking_code: order.tracking_code, parcel: order.Parcel.image.url(:mini),
          parcel_url: order.Parcel.tracking_url}
      else
        extra_data = {hash_id: order.hash_id, date: l(order.created_at, format: :long),
          total: order.total, status: t(order.state), tracking_code: order.tracking_code, parcel: "",
          parcel_url: ""}
      end

      data << extra_data
    end

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }
  end

  def payment_steps
    data = Hash.new
    data[:step1]="Realice el pago total de su compra a una de las siguientes cuentas."
    data[:step2]="Tome una foto, escanee o guarde el archivo del comprobante de pago."
    data[:step3]="Seleccione el comprobante de pago dando click en \“Enviar comprobante de pago\”"
    data[:note]="Si por error eligió un archivo equivocado y desea enviar otro, solo de click nuevamente en \“Enviar comprobante de pago\” y seleccione el correcto."

    bank_accounts = BankAccount.all
    extra_data = Array.new
    bank_accounts.each do |account|
      extra_data << {bank_name: account.bank_name, account_number: account.account_number, interbank_clabe: account.interbank_clabe,
                     owner: account.owner, email: account.email, RFC: account.RFC}
    end

    data[:bank_data] = extra_data
    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }
  end

  def show
    if !params[:notification].blank?
      notification = Notification.find(params[:notification])
      notification.update_attributes(seen: true)
    end

    order = @current_user.Orders.where(hash_id: params[:id]).take
    if order.blank?
      render :status => 200,
             :json => { :success => false, :info => "ORDER_NOT_FOUND" }
      return
    end

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

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }
  end

  def create
    if params[:invoice]=="1" and @current_user.FiscalData.nil?
      render :status => 200,
             :json => { :success => false, :info => "FISCAL_DATA_NOT_FOUND" }
      return
    end

    order = Order.new

    # find the corresponding distributor #
    order.distributor_id = 0
    distributor = @current_user.City.Distributor
    if !distributor.nil?
      order.distributor_id = distributor.id
    end

    # save some order values #
    order.client_id = @current_user.id
    order.city_id = @current_user.city_id
    order.invoice = params[:invoice] if !params[:invoice].blank?
    order.state = "WAITING_FOR_PAYMENT"

    order.hash_id = random_hash_id(12).upcase

    # find the products the client want to buy #
    products = WarehouseProduct.where("hash_id in (?) and describes_total_stock = 1",
                      params[:product_details].keys).includes(:Product)

    products.each do |product|
      if product.existence < params[:product_details][product.hash_id].to_i
        render :status => 200,
               :json => { :success => false, :info => "NO_ENOUGH_EXISTENCE", :data => {product: product.hash_id, existence: product.existence} }
        return
      end
    end

    product_prices = @current_user.ProductPrices.where("product_id in (?)", products.map(&:product_id))

    # get the warehouse he belogs to #
    warehouse = products[0].Warehouse
    order.warehouse_id = warehouse.id

    # get the corresponding prices and create the details of the order #
    order_details = Array.new
    total = 0
    current_product_price = 0
    products.each do |p|
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

      subtotal = params[:product_details][p.hash_id].to_i*current_product_price
      total+=subtotal

      total_iva = current_product_price-(current_product_price*100/(p.Product.iva+100))
      total_ieps = (current_product_price-total_iva)-((current_product_price-total_iva)*100/(p.Product.ieps+100))

      order_details << OrderDetail.new(product_id: p.product_id,
                  hash_id: random_hash_id(12).upcase, iva: p.Product.iva,
                  quantity: params[:product_details][p.hash_id], sub_total: subtotal,
                  w_product_id: p.id, ieps: p.Product.ieps, price: current_product_price,
                  total_iva: total_iva * params[:product_details][p.hash_id].to_i,
                  total_ieps: total_ieps * params[:product_details][p.hash_id].to_i)
    end # products.each do #

    shipping_cost = 0.0
    if total < warehouse.wholesale
      total = total + warehouse.shipping_cost
      shipping_cost = warehouse.shipping_cost
    end
    order.total = total
    order.shipping_cost = shipping_cost

    # finally save all the stuff to the database #
    saved = false
    ActiveRecord::Base.transaction do
      order.save
      products.each do |p|
        p.update_attributes(existence: (p.existence-params[:product_details][p.hash_id].to_i))
      end
      order_details.each do |detail|
        detail.order_id = order.id
        detail.save
      end
      saved = true
    end

    if saved == true
      render :status => 200,
             :json => { :success => true, :info => "SAVED" }
    else
      render :status => 200,
             :json => { :success => false, :info => "SAVE_ERROR" }
    end
  end

  def cancel
    order = @current_user.Orders.where(hash_id: params[:id]).take

    ActiveRecord::Base.transaction do
      details = OrderDetail.where(order_id: order.id)

      details.each do |d|
        query = "UPDATE warehouse_products "+
            "SET existence=(existence+#{d.quantity}) WHERE "+
            "id="+d.w_product_id.to_s
        ActiveRecord::Base.connection.execute(query)
      end

      if order.update(state: "ORDER_CANCELED")
        render :status => 200,
               :json => { :success => true, :info => "SAVED" }
      else
        render :status => 200,
               :json => { :success => false, :info => "SAVE_ERROR" }
      end

    end
  end

  def upload_payment
    order = @current_user.Orders.find_by!(hash_id: params[:id])

    if params[:payment].blank?
      render :status => 200,
             :json => { :success => false, :info => "PAYMENT_NOT_FOUND" }
      return
    end

    if params[:payment].content_type.include? "pdf"
      order.remove_pay_img! if !order.pay_img.blank?
      order.pay_pdf = params[:payment]
    elsif params[:payment].content_type.include? "image"
      order.remove_pay_pdf! if !order.pay_pdf.blank?
      order.pay_img = params[:payment]
    else
      render :status => 200,
             :json => { :success => false, :info => "FILE_FORMAT_ERROR" }
      return
    end
    order.state = "PAYMENT_DEPOSITED"

    if order.save
      render :status => 200,
             :json => { :success => true, :info => "SAVED" }
    else
      render :status => 200,
             :json => { :success => false, :info => "SAVE_ERROR" }
    end
  end
end
