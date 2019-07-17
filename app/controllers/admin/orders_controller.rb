class Admin::OrdersController < AdminController
  # Order States #
  # ORDER_CANCELED #
  # LOCAL #
  # PICKED_UP #
  # WAITING_FOR_PAYMENT #
  # PAYMENT_DEPOSITED #
  # PAYMENT_ACCEPTED #
  # PAYMENT_REJECTED #
  # BATCHES_CAPTURED #
  # INSPECTIONED #
  # SENT #
  # DELIVERED #

  def index
    permission = params[:type]
    permission = "SHOW" if permission == "SENT" or permission == "DELIVERED"
    if params[:type]
      deny_access! and return unless @current_user.has_permission?("orders@#{permission}")
    end

    @label_styles = get_label_styles
    statements = whereAndOrderStatements()
    @orders = Array.new and return unless statements

    statements = warehouseStatement(statements)
    @orders = getOrdersFor(statements).paginate(page: params[:page], per_page: 25)
    render :local_orders if params[:type] == "LOCAL_ORDERS"
  end # def index #

  def accept_pay
    deny_access! and return unless @current_user.has_permission?("orders@accept_reject_payment")

    @order = Order.find_by!(hash_id: params[:id])
    if params[:accept] == "true"
      if Order.find_by(payment_folio: params[:payment_folio])
        # That Folio has already been used 
        flash[:info] = "El folio del pago ya ha sido registrado previamente."
        redirect_to admin_orders_path(type: "ACCEPT_REJECT_PAYMENT") and return
      end

      # Accept the payment
      new_state = params[:local_order].present? ? "PAYMENT_ACCEPTED_LOCAL" : "PAYMENT_ACCEPTED"
      @order.update_attributes(state: new_state, reject_description: nil, payment_folio: params[:payment_folio])

      OrderAction.create(order_id: @order.id, worker_id: @current_user.id, description: "Aceptó/Verificó el pago")
    else
      # Reject the payment and notify the user
      @order.update_attributes(state:"PAYMENT_REJECTED", reject_description: params[:order][:reject_description])
      Notification.create(client_id: @order.client_id, icon: "fa fa-comments-o",
        description: "El pago de tu pedido ha sido rechazado", url: client_order_path(@order.Client.hash_id, @order.hash_id))
      OrderAction.create(order_id: @order.id, worker_id: @current_user.id, description: "Rechazó pago")
    end

    flash[:success] = t(@order.state)
    if params[:local_order].present?
      redirect_to admin_orders_path(type: "LOCAL_ORDERS")
    else
      redirect_to admin_orders_path(type: "ACCEPT_REJECT_PAYMENT")
    end
  end # def accept_pay #

  def details
    require "barby"
    require "barby/barcode/code_128"
    require "barby/outputter/png_outputter"

    deny_access! and return unless @current_user.has_permission?("orders@show")

    @order = Order.find_by!(hash_id: params[:id])
    @order_address = @order.address_hash

    @details = @order.Details.includes(:Product) unless params[:only_address]
    @client = @order.Client
    @fiscal_data = @client.FiscalData
    if !@fiscal_data.blank?
      @city = @fiscal_data.City
      @state = @city.State
    end

    @client_city = @current_user.City
    @client_state = State.where(id: @client_city.state_id).take

    @barcode = Barby::Code128.new(@order.hash_id).to_image.to_data_url

    if params[:only_address]
      render "shared/orders/address", layout: false
    else
      render "shared/orders/details", layout: false
    end
  end # def details #

  def cancel
    deny_access! and return unless @current_user.has_permission?("orders@cancel")

    @order = Order.find_by!(hash_id: params[:id])
    deny_access! and return unless ["WAITING_FOR_PAYMENT","PAYMENT_REJECTED","LOCAL"]

    ActiveRecord::Base.transaction do
      @details = OrderDetail.where(order_id: @order.id)

      @details.each do |d|
        query = "UPDATE warehouse_products "+
            "SET existence=(existence+#{d.quantity}) WHERE "+
            "id="+d.w_product_id.to_s
        ActiveRecord::Base.connection.execute(query)
      end

      @order.update(state: "ORDER_CANCELED", cancel_description: params[:order][:cancel_description])
      Notification.create(client_id: @order.client_id, icon: "fa fa-comments-o",
        description: "Pedido cancelado", url: client_order_path(@order.Client.hash_id, @order.hash_id))
      OrderAction.create(order_id: @order.id, worker_id: @current_user.id, description: "Canceló la orden")
      flash[:success] = "La orden se canceló correctamente."
    end

    flash[:info] = "Oops, algo no salió como lo esperado..." unless flash[:success].present?
    redirect_to admin_orders_path(type: "CANCEL")
  end # def cancel #

  def inspection
    deny_access! and return unless @current_user.has_permission?("orders@inspection")
    @order = Order.find_by!(hash_id: params[:id])

    if @order.update_attribute(:state, "INSPECTIONED")
      flash[:success] = "Estado de orden guardado"
      OrderAction.create(order_id: @order.id, worker_id: @current_user.id, description: "Inspeccionó la orden")
    else
      flash[:info] = "Ocurrió un error al guardar la información"
    end

    redirect_to admin_orders_path + "?type=INSPECTION"
  end # def supplied #

  def supply_error
    deny_access! and return unless @current_user.has_permission?("orders@inspection")

    order = Order.find_by!(hash_id: params[:id])
    shipment_details = OrderProductShipmentDetail.where(order_id: order.id)

    warehouse = order.Warehouse
    warehouse_products = warehouse.Products.where(describes_total_stock: false, 
      product_id: shipment_details.map {|d| d.product_id}, batch: shipment_details.map {|d| d.batch})

    shipment_details.each do |detail|
      warehouse_products.each do |warehouse_product|
        if detail.product_id == warehouse_product.product_id and detail.batch == warehouse_product.batch
          warehouse_product.update_attribute(:existence, warehouse_product.existence + detail.quantity)
        end # if end #
      end # warehouse_products.each #
    end # shipment_details.each #

    shipment_details.destroy_all
    order.update_attribute(:state, "PAYMENT_ACCEPTED")
    OrderAction.create(order_id: order.id, worker_id: @current_user.id, description: "Regresó la orden a volver a surtir")
    flash[:success] = "Pedido regresado"
    redirect_to admin_orders_path(type: "INSPECTION")
  end # def supply_error #

  def capture_details
    deny_access! and return unless @current_user.has_permission?("orders@capture_batches")

    @label_styles = get_label_styles
    @order = Order.find_by!(hash_id: params[:id])

    product_ids = Array.new
    @details = @order.Details
    product_ids = @details.map {|d| d.product_id}.uniq
    @products = Product.where("id in (?)", product_ids)
  end # def capture_details #

  def save_details
    deny_access! and return unless @current_user.has_permission?("orders@capture_batches")
    deny_access! and return if params[:product_id].nil?

    order = Order.find_by!(hash_id: params[:id])
    unless ["PAYMENT_ACCEPTED","LOCAL"].include? order.state
      redirect_to admin_orders_path + "?type=CAPTURE_BATCHES" and return
    end

    ActiveRecord::Base.transaction do
      indx = 0
      while indx < params[:product_id].size do
        detail = OrderProductShipmentDetail.create(order_id: order.id, batch: params[:batch][indx],
          product_id: params[:product_id][indx], quantity: params[:quantity][indx], warehouse_id: order.warehouse_id)
        # Rollback if there are any errors
        flash[:info] = detail.errors.full_messages[0] and raise ActiveRecord::Rollback if detail.errors.any?
        # Withdraw the quantity used for the shipment detail
        detail.warehouse_detail.withdraw(detail.quantity) and indx += 1
      end

      shipment_details = OrderProductShipmentDetail.select("product_id, sum(quantity) as t_quantity")
        .where(order_id: order.id).group(:product_id)
      order_details = OrderDetail.select(:product_id, :quantity).where(order_id: order.id)
      # Review quantities to see that are the same that the client wanted
      validation = CustomValidation.validateOrderShipment(order_details, shipment_details)
      flash[:info] = validation[:error_message] and raise ActiveRecord::Rollback unless validation[:success]

      new_state = order.state == "LOCAL" ? "PICKED_UP" : "BATCHES_CAPTURED"
      order.update_attribute(:state, new_state)
      OrderAction.create(order_id: order.id, worker_id: @current_user.id, description: "Capturó lotes y cantidades")
      flash[:success] = "Números de lote y cantidades guardadas"
    end # Transaction #

    if flash[:success].nil? and flash[:info].blank?
      flash[:info] = "Ocurrió un error al guardar, verifica la información introducida" 
    end
    redirect_to admin_orders_path + "?type=CAPTURE_BATCHES"
  end # def save_details #

  def save_tracking_code
    deny_access! and return unless @current_user.has_permission?("orders@capture_tracking_code")

    @order = Order.find_by!(hash_id: params[:id])
    @order.tracking_code = params[:tracking_code]
    @order.state = "SENT"

    if @order.save
      flash[:success] = "Orden actualizada correctamente"
      OrderAction.create(order_id: @order.id, worker_id: @current_user.id, description: "Capturó código de rastreo")
    else
      flash[:info] = "Ocurrió un error al guardar la información"
    end
    redirect_to admin_orders_path + "?type=CAPTURE_TRACKING_CODE"
  end

  def save_as_delivered
    deny_access! and return unless @current_user.has_permission?("orders@stablish_as_delivered")
    @order = Order.find_by!(hash_id: params[:id])

    if @order.update_attribute(:state, "DELIVERED")
      flash[:success]="Status de la orden actualizado"
      OrderAction.create(order_id: @order.id, worker_id: @current_user.id, description: "Estableció como entregado")
    else
      flash[:info]="Ocurrió un error al guardar la información"
    end
    redirect_to admin_orders_path + "?type=SENT"
  end # def save_as_delivered #

  def invoice_delivered
    deny_access! and return unless @current_user.has_permission?("orders@invoices")
    @order = Order.find_by!(hash_id: params[:id])

    if @order.update_attribute(:invoice_sent, true)
      flash[:success]="Status de la orden actualizado"
      OrderAction.create(order_id: @order.id, worker_id: @current_user.id, description: "Facturó")
    else
      flash[:info]="Ocurrió un error al guardar la información"
    end
    redirect_to admin_orders_path + "?type=INVOICES"
  end # def invoice_delivered #

  def search
    deny_access! and return unless @current_user.has_permission?("orders@search")

    @warehouses = Warehouse.all.order(:name)
    if params[:start_date].blank? and params[:end_date].blank? and params[:reference].blank?
      flash.now[:warning] = "Se requiere estipule al menos una fecha de inicio y fin o un folio." and return
    end
    
    if (params[:start_date].present? and params[:end_date].blank?) or
      (params[:end_date].present? and params[:start_date].blank?)
      flash.now[:warning] = "Se requiere estipule la fecha de inicio y también la de fin" and return
    end

    if !params[:reference].blank?
      @order = Order.find_by(hash_id: params[:reference].strip) and return
      flash.now[:warning] = "Orden con referencia: #{params[:reference]} no encontrada :(" and return unless @order
    end

    if params[:warehouse_id]
      @warehouses.each do |w|
        @warehouse = w if w.id == params[:warehouse_id].to_i
      end
    end

    where_statement = ""
    where_statement = "warehouse_id = " + @warehouse.id.to_s + " and " if @warehouse
    
    where_statement += "created_at BETWEEN '#{params[:start_date].strip}' and '#{params[:end_date].strip}'"

    @no_invoice_required_orders = Order.where(state: ["SENT","DELIVERED","PAYMENT_ACCEPTED_LOCAL"])
      .where.not(state: ["PAYMENT_REJECTED","WAITING_FOR_PAYMENT","PAYMENT_DEPOSITED"])
      .where(where_statement).where(invoice: false).includes(:Client, :Distributor, :Details)

    @invoice_required_orders = Order.where(state: ["SENT","DELIVERED","PAYMENT_ACCEPTED_LOCAL"])
      .where.not(state: ["PAYMENT_REJECTED","WAITING_FOR_PAYMENT","PAYMENT_DEPOSITED"])
      .where(where_statement).where(invoice: true).includes(:Client, :Distributor, :Details)

    @orders_to_be_sent = Order.where(state: "BATCHES_CAPTURED").where(where_statement).includes(:Client, :Distributor, :Details)
    @orders_to_be_paid = Order.where(state: ["WAITING_FOR_PAYMENT","PAYMENT_DEPOSITED","LOCAL","PICKED_UP"])
      .where(where_statement).includes(:Client, :Distributor, :Details)
    @label_styles = get_label_styles
  end

  def show_activities
    deny_access! and return unless @current_user.has_permission?("orders@search")
    @order = Order.find_by!(hash_id: params[:id])
    @actions = @order.Actions.order(created_at: :asc).includes(:Worker)
  end

  def download_invoice_data
    # TODO refactor at the end, possibly deprecated
    deny_access! and return unless @current_user.has_permission?("orders@invoices")

    exclude = ["WAITING_FOR_PAYMENT", "ORDER_CANCELED", "PAYMENT_REJECTED",
      "PAYMENT_DEPOSITED", "LOCAL", "PICKED_UP"]

    orders = Order.where(invoice_sent: false)
      .where.not(state: exclude)
      .includes(Client: [:FiscalData], Details: [:Product])

    # if needed the last file send it #
    if params[:current] == "true" or !orders.any?
      send_file "doc/invoices.txt" and return
    end

    last_folio = File.open("doc/last_invoice_folio.txt", "r").gets.to_i

    # if not, replace the old one with the new info #
    f = File.open("doc/invoices.txt", "w")

    # iterate the orders and put the data on the invoices file #
    orders.each do |order|
      last_folio += 1
      #logger.info "/-/-/ #{last_folio}, #{order.hash_id}, order_id: #{order.id} ---"

      now = Time.now
      now = "#{now.year}-#{now.month}-#{now.day}"
      # writting the invoice data #
      f.puts("#{last_folio}|1|#{order.Warehouse.hash_id}|#{now}|CONTADO||México||#{order.hash_id}|#{now}")

      # writting transmitter(Company) data #
      f.puts("#{last_folio}|2|BBM151218UI0|BLACK BROCKET DE MÉXICO S. de R.L. DE C.V.|Galeana|125||Centro|Guadalajara|Guadalajara|Jalisco|México|44100|RÉGIMEN GENERAL DE LEY PERSONAS MORALES")

      # writting receiver(Client) data #
      client = order.Client
      fiscal_data = client.FiscalData
      if !fiscal_data.blank?
        f.puts("#{last_folio}|3|#{client.hash_id}|#{fiscal_data.rfc}|#{fiscal_data.name} "+
        "#{fiscal_data.lastname} #{fiscal_data.mother_lastname}|#{fiscal_data.street}|"+
        "#{fiscal_data.extnumber}|#{fiscal_data.intnumber}|#{fiscal_data.col}||"+
        "#{fiscal_data.City.name}|#{fiscal_data.City.State.name}|México|#{fiscal_data.cp}|#{client.email}")
      else
        f.puts("#{last_folio}|3|#{client.hash_id}||#{client.name} #{client.lastname} "+
        "#{client.mother_lastname}|#{client.street}|#{client.extnumber}|"+
        "#{client.intnumber}|#{client.col}||#{client.City.name}|"+
        "#{client.City.State.name}|México|#{client.cp}|#{client.email}")
      end # if fiscal data #

      # writting products data #
      total_iva = 0
      total_ieps = 0
      order.Details.each do |detail|
        product = detail.Product
        total_iva += detail.total_iva
        total_ieps += detail.total_ieps
        f.puts("#{last_folio}|4|#{product.hash_id}|#{detail.quantity}|#{product.presentation}|"+
        "#{product.name}|#{detail.price}|0|0|||#{detail.total_iva}||#{detail.total_ieps}")
      end # order.Details.each #

      # writting taxes data #
      f.puts("#{last_folio}|5|IVA||#{total_iva}|TUA|||OTROS IMPUESTOS||#{total_ieps}||||||")

      # writting extra data #
      f.puts("#{last_folio}|6||||#{order.shipping_cost}|||")
    end # orders each #
    # File.flush required for large files (or maybe it is a bug) #
    # if not used the file may be incomplete when saved by the system (ruby) #
    f.flush

    # clean the last_invoice_folio file and put in the new last_folio value #
    last_folio_file = File.open("doc/last_invoice_folio.txt", "w+")
    last_folio_file.write(last_folio)
    last_folio_file.flush

    Order.where(id: orders.map { |o| o.id }).update_all(invoice_sent: true)
    orders.each do |o|
      OrderAction.create(order_id: o.id, worker_id: @current_user.id, description: "Facturó")
    end
    # send the file #
    send_file "doc/invoices.txt"
  end

  def download_payment_file
    deny_access! and return unless @current_user.has_permission?("orders@accept_reject_payment")
    order = Order.find_by!(download_payment_key: params[:payment_key])

    if order.pay_img.present?
      send_file order.pay_img.path
    elsif order.pay_pdf.present?
      send_file order.pay_pdf.path
    end
  end

  def upload_payment
    deny_access! and return unless @current_user.has_permission?("orders@local_orders")
    order = Order.find_by!(hash_id: params[:id])
    deny_access! and return if ["PAYMENT_ACCEPTED_LOCAL","LOCAL"].include? order.state

    if params[:order][:pay_img].content_type == "application/pdf"
      order.remove_pay_img! if order.pay_img.present?
      order.pay_pdf = params[:order][:pay_img]
    else
      order.remove_pay_pdf! if order.pay_pdf.present?
      order.pay_img = params[:order][:pay_img]
    end
    
    order.download_payment_key = SecureRandom.urlsafe_base64
    if order.save!
      OrderAction.create(order_id: order.id, worker_id: @current_user.id, description: "Subió comprobante")
      flash[:success] = "Comprobante actualizado"
    else
      flash[:info] = "Ocurrió un error al guardar el comprobante"
    end
    redirect_to admin_orders_path(type: "LOCAL_ORDERS")
  end

  def save_invoice_folio
    deny_access! and return unless @current_user.has_permission?("orders@save_invoice_folio")
    order = Order.find_by!(hash_id: params[:id])
    unless order.invoice_folio.present?
      order.invoice_folio = params[:invoice_folio]
      order.save!
    end
    flash[:success] = "Folio guardado"

    redirect_to admin_orders_path(type: params[:type])
  end

  private
    def get_label_styles
      label_styles =
        {"ORDER_CANCELED"=>"label label-danger",
         "LOCAL"=>"label label-information",
         "PICKED_UP"=>"label label-success",
         "PAYMENT_ACCEPTED_LOCAL"=>"label label-primary",
         "WAITING_FOR_PAYMENT"=>"label label-warning",
         "PAYMENT_DEPOSITED"=>"label label-information",
         "PAYMENT_ACCEPTED"=>"label label-primary",
         "PAYMENT_REJECTED"=>"label label-danger",
         "BATCHES_CAPTURED"=>"label label-primary",
         "INSPECTIONED"=>"label label-primary",
         "SENT"=>"label label-success",
         "DELIVERED"=>"label label-success" }

      return label_styles
    end

    def whereAndOrderStatements
      statements = Hash.new
      statements[:where] = "state="
      statements[:order] = {created_at: :asc}

      case params[:type]
        when "CANCEL"
          statements[:where] = "state in ('WAITING_FOR_PAYMENT','PAYMENT_REJECTED')"
        when "LOCAL_ORDERS"
          statements[:where] = "state in ('LOCAL','PICKED_UP','PAYMENT_ACCEPTED_LOCAL')"
          statements[:order] = {created_at: :desc}
        when "ACCEPT_REJECT_PAYMENT"
          statements[:where] += "'PAYMENT_DEPOSITED'"
        when "CAPTURE_BATCHES"
          statements[:where] += "'PAYMENT_ACCEPTED'"
        when "INSPECTION"
          statements[:where] += "'BATCHES_CAPTURED'"
        when "CAPTURE_TRACKING_CODE"
          statements[:where] += "'INSPECTIONED'"
        when "SENT"
          statements[:where] += "'SENT'"
        when "DELIVERED"
          statements[:where] += "'DELIVERED'"
          statements[:order] = {created_at: :desc}
        when "INVOICES"
          statements[:where] = "state not in ('WAITING_FOR_PAYMENT',
            'ORDER_CANCELED','PAYMENT_REJECTED','PAYMENT_DEPOSITED',
            'LOCAL','PICKED_UP')"
          statements[:order] = {created_at: :desc}
        else
          return if params[:type].blank?
      end # case params[:type] #

      if search_params.present?
        statements[:where] += " and orders.hash_id like '%#{search_params}%'"
      end
      return statements
    end

    def warehouseStatement(statements)
      unless ["CANCEL","ACCEPT_REJECT_PAYMENT","INVOICES"].include? params[:type]
        statements[:warehouse] = @current_user.warehouse_id
      end
      return statements
    end

    def getOrdersFor(statements)
      if params[:distributor].present?
        distributor = Distributor.find_by!(hash_id: params[:distributor])
  
        Order.joins(:Distributor)
          .where(distributors: {hash_id: params[:distributor]})
          .where(statements[:where])
          .byWarehouse(statements[:warehouse])
          .order(statements[:order])
          .includes(City: :State).includes(:Distributor, :Client)
      else
        Order.where(statements[:where])
          .byWarehouse(statements[:warehouse])
          .order(statements[:order])
          .includes(City: :State).includes(:Distributor, :Client)
      end
    end
end
