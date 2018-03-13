class Admin::OrdersController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_worker?
  layout "admin_layout.html.erb"

  # Order States #
  # ORDER_CANCELED #
  # WAITING_FOR_PAYMENT #
  # PAYMENT_DEPOSITED #
  # PAYMENT_ACCEPTED #
  # PAYMENT_REJECTED #
  # BATCHES_CAPTURED #
  # INSPECTIONED #
  # SENT #
  # DELIVERED #

  @@category = "ORDERS"

  def index
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @label_styles = get_label_styles
    @orders = Array.new

    # determine the actions the user can do, so we can display them in screen #
    @actions = {"SHOW"=>false,"CANCEL"=>false,"ACCEPT_REJECT_PAYMENT"=>false,
                "INSPECTION"=>false,
                "CAPTURE_BATCHES"=>false,"CAPTURE_TRACKING_CODE"=>false,
                "STABLISH_AS_SENT"=>false,"STABLISH_AS_DELIVERED"=>false,
                "INVOICES"=>false,"CREATE_COMMISION"=>false,"SEARCH"=>false}

    if !@current_user.is_admin
      @user_permissions.each do |p|
        # see if the permission category is equal to the one we need in these controller #
        if p.category == @@category
          @actions[p.name]=true
        elsif p.category == "COMMISSIONS" and p.name == "CREATE"
          @actions["CREATE_COMMISION"]=true
        end # if p.category == @@category #
      end # @user_permissions.each end #
    else
      @actions = {"SHOW"=>true,"CANCEL"=>true,"ACCEPT_REJECT_PAYMENT"=>true,
                  "INSPECTION"=>true,
                  "CAPTURE_BATCHES"=>true,"CAPTURE_TRACKING_CODE"=>true,
                  "STABLISH_AS_SENT"=>true,"STABLISH_AS_DELIVERED"=>true,
                  "INVOICES"=>true,"CREATE_COMMISION"=>true,"SEARCH"=>true}
    end # if !@current_user.is_admin end #

    type_of_order_is_correct = true
    where_statement = "state="
    order_statement = {created_at: :asc}
    if @actions[params[:type]] or
       params[:type] == "SENT" or
       params[:type] == "DELIVERED"

      case params[:type]
        when "CANCEL"
          where_statement += "'WAITING_FOR_PAYMENT' or state='PAYMENT_REJECTED'"
        when "ACCEPT_REJECT_PAYMENT"
          where_statement += "'PAYMENT_DEPOSITED'"
        when "CAPTURE_BATCHES"
          where_statement += "'PAYMENT_ACCEPTED'"
        when "INSPECTION"
          where_statement += "'BATCHES_CAPTURED'"
        when "CAPTURE_TRACKING_CODE"
          where_statement += "'INSPECTIONED'"
        when "SENT"
          where_statement += "'SENT'"
        when "DELIVERED"
          where_statement += "'DELIVERED'"
          order_statement = {created_at: :desc}
        when "INVOICES"
          where_statement = "state not in ('WAITING_FOR_PAYMENT','ORDER_CANCELED','PAYMENT_REJECTED','PAYMENT_DEPOSITED')"
          order_statement = {created_at: :desc}
        else
          type_of_order_is_correct = false
      end # case params[:type] #
    else
      type_of_order_is_correct = false
    end # if @actions[params[:type]] #

    if type_of_order_is_correct

      if @actions["CAPTURE_TRACKING_CODE"] and
        !params[:type].blank? and params[:type] == "CAPTURE_TRACKING_CODE"
        @parcels = Parcel.where(warehouse_id: @current_user.warehouse_id)
      end # if @actions["CAPTURE_TRACKING_CODE"] #

      where_warehouse = {}
      if ["CANCEL","ACCEPT_REJECT_PAYMENT","INVOICES"].include? params[:type]
        where_warehouse = "true"
      else
        where_warehouse = {warehouse_id: @current_user.warehouse_id}
      end # if ["CANCEL","ACCEPT_REJECT_PAYMENT","INVOICES"].include? params[:type] #

      if !params[:distributor].nil?
        distributor = Distributor.find_by!(:hash_id => params[:distributor])
        if distributor.nil?
          flash[:info] = "No se encontró el distribuidor con clave: #{params[:distributor]}"
          redirect_to admin_distributors_path
          return
        end

        @orders = Order.joins(:Distributor)
            .where(distributors: {hash_id: params[:distributor]})
            .where(where_statement)
            .where(where_warehouse)
            .order(order_statement)
            .paginate(:page =>  params[:page], :per_page => 25)
            .includes(City: :State).includes(:Distributor, :Client)
      else
        @orders = Order.where(where_statement)
            .where(where_warehouse)
            .order(order_statement)
            .paginate(:page =>  params[:page], :per_page => 25)
            .includes(City: :State).includes(:Distributor, :Client)
      end # if !params[:distributor].nil? #
    end

  end # def index #

  def accept_pay
    authorization_result = @current_user.is_authorized?(@@category, "ACCEPT_REJECT_PAYMENT")
    return if !process_authorization_result(authorization_result)

    @order = Order.where(hash_id: params[:id]).take
    if @order
      if params[:accept] == "true"
        if Order.find_by!(payment_folio: params[:payment_folio])
          #Duplicate folio
          flash[:info] = "El folio del pago ya ha sido registrado previamente."
          redirect_to admin_orders_path(type: 'ACCEPT_REJECT_PAYMENT')
          return
        end
        #Accept the payment
        @saved=true if @order.update_attributes(state:"PAYMENT_ACCEPTED", reject_description: nil, payment_folio: params[:payment_folio])
        OrderAction.create(order_id: @order.id, worker_id: @current_user.id, description: "Aceptó pago")
      else
        #Reject the payment and notify the user
        @saved=true if @order.update_attributes(state:"PAYMENT_REJECTED", reject_description: params[:order][:reject_description])
        Notification.create(client_id: @order.client_id, icon: "fa fa-comments-o",
                        description: "El pago de tu pedido ha sido rechazado", url: client_order_path(@order.Client.hash_id, @order.hash_id))
        OrderAction.create(order_id: @order.id, worker_id: @current_user.id, description: "Rechazó pago")
      end
    end

    if @saved==true
      flash[:success]=t(@order.state)
    else
      flash[:danger]="Ocurrió un error al procesar el pago, inténtalo de nuevo por favor"
    end

    redirect_to admin_orders_path(type: "ACCEPT_REJECT_PAYMENT")
  end # def accept_pay #

  def details
    authorization_result = @current_user.is_authorized?(@@category, "SHOW")
    return if !process_authorization_result(authorization_result)

    @order = Order.find_by!(hash_id: params[:id])

    if @order
      if !params[:only_address] or params[:only_address] != "Y"
        @details = @order.Details.includes(:Product)
      end
      @client = @order.Client
      @fiscal_data = @client.FiscalData
      if !@fiscal_data.blank?
        @city = @fiscal_data.City
        @state = @city.State
      end

      @client_city = @current_user.City
      @client_state = State.where(id: @client_city.state_id).take

      render :details, layout: false
      return
    else
      flash[:info] = "No se encontró la orden con clave: #{params[:id]}"
      redirect_to admin_orders_path
      return
    end
  end # def details #

  def cancel
    authorization_result = @current_user.is_authorized?(@@category, "CANCEL")
    return if !process_authorization_result(authorization_result)

    @order = Order.find_by!(hash_id: params[:id])

    if @order
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
      end

      flash[:success] = "La orden se canceló correctamente."
    end

    flash[:danger] = "Oops, algo no salió como lo esperado..." if flash[:success].nil?
    redirect_to admin_orders_path(type: "CANCEL")
  end # def cancel #

  def inspection
    authorization_result = @current_user.is_authorized?(@@category, "INSPECTION")
    return if !process_authorization_result(authorization_result)

    @order = Order.find_by!(hash_id: params[:id])
    success = false
    if @order
      success = true if @order.update_attribute(:state, "INSPECTIONED")
    end # if @order #

    if success
      flash[:success] = "Estado de orden guardado"
      OrderAction.create(order_id: @order.id, worker_id: @current_user.id, description: "Inspeccionó la orden")
    else
      flash[:danger] = "Ocurrió un error al guardar la información"
    end

    redirect_to admin_orders_path + "?type=INSPECTION"
  end # def supplied #

  def supply_error
    authorization_result = @current_user.is_authorized?(@@category, "INSPECTION")
    return if !process_authorization_result(authorization_result)

    order = Order.find_by!(hash_id: params[:id])
    shipment_details = OrderProductShipmentDetail.where(order_id: order.id)

    warehouse = order.Warehouse
    warehouse_products = warehouse.Products.where(describes_total_stock: false, product_id: shipment_details.map {|d| d.product_id})

    shipment_details.each do |detail|
      warehouse_products.each do |warehouse_product|
        if detail.product_id == warehouse_product.product_id and detail.batch == warehouse_product.batch
          warehouse_product.update_attribute(:existence, warehouse_product.existence + detail.quantity)
          break
        end # if end #
      end # warehouse_products.each #
    end # shipment_details.each #

    shipment_details.destroy_all
    order.update_attribute(:state, "PAYMENT_ACCEPTED")
    OrderAction.create(order_id: order.id, worker_id: @current_user.id, description: "Regresó la orden a volver a surtir")
    flash[:success] = "Pedido regresado"
    redirect_to admin_orders_path(type: "INSPECTION")
  end

  def capture_details
    authorization_result = @current_user.is_authorized?(@@category, "CAPTURE_BATCHES")
    return if !process_authorization_result(authorization_result)

    @label_styles = get_label_styles
    @order = Order.find_by!(hash_id: params[:id])

    if @order
      product_ids = Array.new
      @details = @order.Details
      @details.each do |detail|
        if !product_ids.include?(detail.product_id)
          product_ids << detail.product_id
        end # if !product_ids.include?(detail.product_id) #
      end # @details.each #

      @products = Product.where("id in (?)", product_ids)
    end # if @order #
  end # def capture_details #

  def save_details
    authorization_result = @current_user.is_authorized?(@@category, "CAPTURE_BATCHES")
    return if !process_authorization_result(authorization_result)

    success = false
    @order = Order.find_by!(hash_id: params[:id])

    if @order and @order.state == "PAYMENT_ACCEPTED"
      ActiveRecord::Base.transaction do

        indx = 0
        while indx < params[:product_id].size do
          product_detail =
            WarehouseProduct.where(warehouse_id: @order.warehouse_id,
                                   product_id: params[:product_id][indx],
                                   batch: params[:batch][indx]).take

          # if the product with the given key and batch doesn't exist stop the execution #
          if !product_detail
            puts "--- product not found ---"
            flash[:danger] = "No existe el producto con clave #{params[:product_id][indx]} y No. de lote #{params[:batch][indx]}."
            raise ActiveRecord::Rollback
            break
          end # if !product_detail #

          # if the current existence of the product is less than the one captured stop the execution #
          if product_detail.existence >= params[:quantity][indx].to_i
            product_detail.update_attribute(:existence,
                          product_detail.existence - params[:quantity][indx].to_i)
          else
            puts "--- no enough existence for delivery ---"
            flash[:danger] = "No hay existencias suficientes."
            raise ActiveRecord::Rollback
            break
          end

          OrderProductShipmentDetail.create(order_id: @order.id,
                          product_id: params[:product_id][indx],
                          quantity: params[:quantity][indx],
                          batch: params[:batch][indx])

          indx += 1
        end # while indx < params[:product_id].size #

        # review quantities to see that are the same that the client wanted
        shipment_details = OrderProductShipmentDetail.select("product_id, sum(quantity) as t_quantity")
                              .where(order_id: @order.id).group(:product_id)
        order_details = OrderDetail.select(:product_id, :quantity).where(order_id: @order.id)

        product_captured = true
        order_details.each do |order_detail|

          # if a product hasn't been captured stop the execution #
          if !product_captured
            puts "--- a product hasn't been captured ---"
            flash[:danger] = "No se esta surtiendo el pedido completo."
            raise ActiveRecord::Rollback
            break
          end

          product_captured = false
          shipment_quantity = 0

          # iterate through the shipment details to verify the product quantities are the ones the client wanted #
          shipment_details.each do |shipment_detail|
            if order_detail.product_id == shipment_detail.product_id
              shipment_quantity += shipment_detail.t_quantity
            end
          end

          if order_detail.quantity != shipment_quantity
            puts "--- quantities don't match ---"
            flash[:danger] = "La cantidad de productos a enviar no es correcta."
            raise ActiveRecord::Rollback
            break
          else
            product_captured = true
          end
        end

        @order.update_attribute(:state, "BATCHES_CAPTURED")
        puts "--- every thing went OK while validating quantities ---"
        success = true
      end # Transaction #

    end # if @order #

    if success
      flash[:success] = "Números de lote y cantidades guardadas"
      OrderAction.create(order_id: @order.id, worker_id: @current_user.id, description: "Capturó lotes y cantidades")
    else
      flash[:danger] = "Ocurrió un error al guardar, verifica la información introducida" if flash[:danger].blank?
    end
    redirect_to admin_orders_path + "?type=CAPTURE_BATCHES"

  end # def save_details #

  def save_tracking_code
    authorization_result = @current_user.is_authorized?(@@category, "CAPTURE_TRACKING_CODE")
    return if !process_authorization_result(authorization_result)

    success = false
    @order = Order.find_by!(hash_id: params[:id])

    if @order
      @order.tracking_code = params[:tracking_code]
      @order.parcel_id = params[:parcel_id]
      @order.state = "SENT"
      success = true if @order.save
    end # if @order #

    if success
      flash[:success] = "Orden actualizada correctamente"
      OrderAction.create(order_id: @order.id, worker_id: @current_user.id, description: "Capturó código de rastreo")
    else
      flash[:danger] = "Ocurrió un error al guardar la información"
    end
    redirect_to admin_orders_path + "?type=CAPTURE_TRACKING_CODE"
  end

  def save_as_delivered
    authorization_result = @current_user.is_authorized?(@@category, "STABLISH_AS_DELIVERED")
    return if !process_authorization_result(authorization_result)

    success = false
    @order = Order.find_by!(hash_id: params[:id])
    success = true if @order.update_attribute(:state, "DELIVERED")

    if success
      flash[:success]="Status de la orden actualizado"
      OrderAction.create(order_id: @order.id, worker_id: @current_user.id, description: "Estableció como entregado")
    else
      flash[:danger]="Ocurrió un error al guardar la información"
    end
    redirect_to admin_orders_path + "?type=SENT"
  end # def save_as_delivered #

  def invoice_delivered
    authorization_result = @current_user.is_authorized?(@@category, "INVOICES")
    return if !process_authorization_result(authorization_result)

    success = false
    @order = Order.find_by!(hash_id: params[:id])
    success = true if @order.update_attribute(:invoice_sent, true)

    if success
      flash[:success]="Status de la orden actualizado"
      OrderAction.create(order_id: @order.id, worker_id: @current_user.id, description: "Facturó")
    else
      flash[:danger]="Ocurrió un error al guardar la información"
    end
    redirect_to admin_orders_path + "?type=INVOICES"
  end # def invoice_delivered #

  def search
    authorization_result = @current_user.is_authorized?("ORDERS", "SEARCH")
    return if !process_authorization_result(authorization_result)

    @warehouses = Warehouse.all.order(:name)
    if params[:start_date].blank? and params[:end_date].blank? and params[:reference].blank?
      flash.now[:warning] = "Se requiere se estipule al menos una fecha de inicio y fin o un folio."
      return
    end

    if !params[:reference].blank?
      @order = Order.find_by!(hash_id: params[:reference].strip)
      if @order.blank?
        flash.now[:warning] = "Orden con referencia: #{params[:reference]} no encontrada :("
      end
      return
    end

    @warehouse = ""
    if params[:warehouse_id]
      @warehouses.each do |w|
        @warehouse = w if w.id == params[:warehouse_id].to_i
      end
    end

    where_statement = ""
    if !@warehouse.blank?
      where_statement = "warehouse_id = " + @warehouse.id.to_s + " and "
    end
    where_statement += "created_at BETWEEN '#{params[:start_date].strip}' and '#{params[:end_date].strip}'"

    @no_invoice_required_orders = Order.where.not(state: ["PAYMENT_REJECTED","WAITING_FOR_PAYMENT","PAYMENT_DEPOSITED"])
                                  .where(state: ["SENT","DELIVERED"])
                                  .where(where_statement).where(invoice: false).includes(:Client, :Distributor, :Details)

    @invoice_required_orders = Order.where.not(state: ["PAYMENT_REJECTED","WAITING_FOR_PAYMENT","PAYMENT_DEPOSITED"])
                                  .where(state: ["SENT","DELIVERED"])
                                  .where(where_statement).where(invoice: true).includes(:Client, :Distributor, :Details)

    @orders_to_be_sent = Order.where(state: "BATCHES_CAPTURED").where(where_statement).includes(:Client, :Distributor, :Details)
    @orders_to_be_paid = Order.where(state: ["WAITING_FOR_PAYMENT", "PAYMENT_DEPOSITED"]).where(where_statement).includes(:Client, :Distributor, :Details)
    @label_styles = get_label_styles

  end

  def show_activities
    authorization_result = @current_user.is_authorized?(@@category, "SEARCH")
    return if !process_authorization_result(authorization_result)

    @order = Order.find_by!(hash_id: params[:id])

    # if non order was found redirect to other action #
    if @order.blank?
      flash[:warning] = "No se encontró la orden especificada."
      redirect_to admin_orders_search_path
      return
    end

    @actions = @order.Actions.order(created_at: :asc)
  end

  def download_invoice_data
    authorization_result = @current_user.is_authorized?(@@category, "INVOICES")
    return if !process_authorization_result(authorization_result)

    orders = Order.where(invoice_sent: false).where.not(state: ['WAITING_FOR_PAYMENT','ORDER_CANCELED','PAYMENT_REJECTED','PAYMENT_DEPOSITED']).includes(Client: [:FiscalData], Details: [:Product])

    # if needed the last file send it #
    if params[:current] == "true"
      send_file "doc/invoices.txt"
      return
    end

    last_folio = File.open("doc/last_invoice_folio.txt", "r").gets.to_i

    # if not, replace the old one with the new info #
    f = File.open("doc/invoices.txt", "w")

    # iterate the orders and put the data on the invoices file #
    orders.each do |order|
      last_folio += 1
      #puts "--- #{last_folio}, #{order.hash_id}, order_id: #{order.id} ---"

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
    authorization_result = @current_user.is_authorized?(@@category, "ACCEPT_REJECT_PAYMENT")
    return if !process_authorization_result(authorization_result)

    order = Order.find_by!(download_payment_key: params[:payment_key])
    if !order
      redirect_to admin_welcome_path
      flash[:waring] = "No se encontró la orden especificada."
      return
    end

    if !order.pay_img.file.nil?
      send_file order.pay_img.path
    elsif !order.pay_pdf.file.nil?
      send_file order.pay_pdf.path
    end
  end

  private
    def get_label_styles
      label_styles =
        {"ORDER_CANCELED"=>"label label-danger",
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

end
