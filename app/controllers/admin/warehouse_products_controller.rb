class Admin::WarehouseProductsController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_worker?
  layout "admin_layout.html.erb"

  @@manager_category = "WAREHOUSE_MANAGER"
  @@category = "WAREHOUSE_PRODUCTS"

  def index
    manager_authorization_result = @current_user.is_authorized?(@@manager_category, nil)
    authorization_result = @current_user.is_authorized?(@@category, nil)

    session[:shipment_products] = Hash.new if !session[:shipment_products]

    if process_authorization_result(authorization_result, false)
      redirect_to admin_chief_warehouse_products_path(params[:warehouse_id])
      return
    elsif !process_authorization_result(manager_authorization_result, false)
      redirect_to admin_welcome_path
      return
    end

    @warehouse = @current_user.Warehouse

    @products = @warehouse.Products.joins(:Product).where(:describes_total_stock => true, products: {deleted: false}).includes(:Product).order("products.name asc").paginate(page: params[:page], per_page: 20)

    # determine the actions the user can do, so we can display them in screen #
    @actions = {"RECEIVE_SHIPMENTS"=>false,"TRANSFER_MERCANCY"=>false,"UPDATE_STOCK"=>false}
    if !@current_user.is_admin
      @user_permissions.each do |p|
        # see if the permission category is equal to the one we need in these controller #
        if p.category == @@manager_category
          @actions[p.name]=true
        end # if p.category == @@category #
      end # @user_permissions.each end #
    else
      @actions = {"RECEIVE_SHIPMENTS"=>true,"TRANSFER_MERCANCY"=>true,"UPDATE_STOCK"=>true}
    end # if !@current_user.is_admin end #

    if @actions["TRANSFER_MERCANCY"]
      @warehouses = Warehouse.where.not(id: @current_user.warehouse_id).where(deleted: false)
    end
  end # def index #

  def stock_details
    authorization_result = @current_user.is_authorized?(@@manager_category, "UPDATE_STOCK")
    return if !process_authorization_result(authorization_result)

    @warehouse = Warehouse.find_by(hash_id: params[:warehouse_id])
    @product = Product.find(params[:id])
    @stock_details = @warehouse.Products.where(product_id: params[:id], describes_total_stock: false)
  end # def stock_details #

  def update_stock
    authorization_result = @current_user.is_authorized?(@@manager_category, "UPDATE_STOCK")
    return if !process_authorization_result(authorization_result)

    warehouse = Warehouse.find_by(hash_id: params[:warehouse_id])
    product = Product.find(params[:id])

    master_detail = WarehouseProduct.where(warehouse_id: warehouse.id,
                      product_id: product.id, describes_total_stock: true).take

    detail = WarehouseProduct.where(warehouse_id: warehouse.id,
                      product_id: product.id, describes_total_stock: false,
                      batch: params[:warehouse_product][:batch],
                      expiration_date: params[:warehouse_product][:expiration_date]).take

    success = false
    ActiveRecord::Base.transaction do
      difference = detail.existence - params[:warehouse_product][:existence].to_i

      master_detail.update_attributes(existence: master_detail.existence - difference)
      detail.update_attributes(existence: detail.existence - difference)

      success = true
    end

    flash[:success] = "Stock modificado" if success
    flash[:danger] = "Ocurrió un error al modificar el stock." if !success
    redirect_to admin_warehouse_products_stock_details_path(warehouse.hash_id, product.id)
  end

  def chief_index
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    session[:shipment_products] = Hash.new if !session[:shipment_products]

    @warehouse = Warehouse.find_by(hash_id: params[:warehouse_id])
    if @warehouse.nil?
      flash[:info] = "No se encontró el almacén con clave: #{params[:id]}"
      redirect_to admin_warehouses_path
      return
    end

    @actions = {"SHOW"=>false,"CREATE_SHIPMENTS"=>false,"DELETE_SHIPMENTS"=>false,
      "REJECT_SHIPMENT_STOCK"=>false,"UPDATE_MIN_STOCK"=>false,
      "SHOW_SHIPMENTS"=>false,"INVENTORY"=>false}
    if !@current_user.is_admin
      @user_permissions.each do |p|
        # see if the permission category is equal to the one we need in these controller #
        if p.category == @@category
          @actions[p.name]=true
        end # if p.category == @@category #
      end # @user_permissions.each end #
    else
      @actions = {"SHOW"=>true,"CREATE_SHIPMENTS"=>true,"DELETE_SHIPMENTS"=>true,
        "REJECT_SHIPMENT_STOCK"=>true,"UPDATE_MIN_STOCK"=>true,
        "SHOW_SHIPMENTS"=>true,"INVENTORY"=>true}
    end # if !@current_user.is_admin end #

    if @actions["SHOW"]
      @products = @warehouse.Products.joins(:Product).where(:describes_total_stock => true, products: {deleted: false}).includes(:Product).order("products.name asc").paginate(page: params[:page], per_page: 20)
    end
  end

  def prepare_product_for_shipment
    authorization_result = @current_user.is_authorized?(@@category, "CREATE_SHIPMENTS")
    if !authorization_result.any?
      authorization_result = @current_user.is_authorized?(@@manager_category, "TRANSFER_MERCANCY")
    end
    return if !process_authorization_result(authorization_result)

    if !session[:shipment_products]
      session[:shipment_products] = Hash.new
    end
    if session[:shipment_products]["warehouse"] != params[:warehouse_id]
      session[:shipment_products] = {:warehouse => params[:warehouse_id]}
    end

    @hash = Hash.new
    @hash_id = random_hash_id(12).upcase

    @hash[params[:id]] = {"name" => params[:warehouse_product][:name],
            @hash_id => {"quantity" => params[:warehouse_product][:quantity],
                         "batch" => params[:warehouse_product][:batch],
                         "expiration_date" => params[:warehouse_product][:expiration_date]}}

    if session[:shipment_products][params[:id]].blank?
      session[:shipment_products][params[:id]] = {}
    end
    session[:shipment_products][params[:id]][@hash_id] = @hash[params[:id]][@hash_id]
    session[:shipment_products][params[:id]][:name] = params[:warehouse_product][:name]

    respond_to do |format|
      format.js { render :prepare_product_for_shipment, :layout => false }
    end
  end

  def discard_shipment_preparation
    authorization_result = @current_user.is_authorized?(@@category, "CREATE_SHIPMENTS")
    if !authorization_result.any?
      authorization_result = @current_user.is_authorized?(@@manager_category, "TRANSFER_MERCANCY")
    end
    return if !process_authorization_result(authorization_result)

    @k = nil
    session[:shipment_products].keys.each do |k|
      if k != "warehouse"
        has_the_target = session[:shipment_products][k].has_key?(params[:id])
        if has_the_target
          session[:shipment_products][k].delete(params[:id])
          @k = k
        end
      end
    end

    if @k and session[:shipment_products][@k].keys.size <= 1
      session[:shipment_products].delete(@k)
      @remove_container = true
    end

    respond_to do |format|
      format.js { render :discard_shipment_preparation, :layout => false }
    end
  end

  def create_shipment
    authorization_result = @current_user.is_authorized?(@@category, "CREATE_SHIPMENTS")
    if !authorization_result.any?
      puts "--- going to check if the user can TRANSFER_MERCANCY ---"
      authorization_result = @current_user.is_authorized?(@@manager_category, "TRANSFER_MERCANCY")
    end
    return if !process_authorization_result(authorization_result)

    warehouse = Warehouse.find_by(hash_id: params[:warehouse_id])
    if warehouse.nil?
      flash[:info] = "No se encontró el almacén con clave: #{params[:warehouse_id]}"
      redirect_to admin_warehouses_path
      return
    end

    if params[:shipment] and params[:shipment][:type] == "TRANSFER"
      puts "--- the shipment is a transfer ---"
      shipment = Shipment.new(target_warehouse_id: params[:shipment][:target_warehouse_id],
      origin_warehouse_id: warehouse.id, chief_id: @current_user.id, shipment_type: "TRANSFER")
    else
      puts "--- the shipment is not a transfer ---"
      shipment = Shipment.new(target_warehouse_id: warehouse.id,
      chief_id: @current_user.id, shipment_type: "NEW_BATCHES")
    end

    success = true
    ActiveRecord::Base.transaction do
      session[:shipment_products].delete("warehouse")
      puts "--- loading products ---"
      products = Product.select(:id, :hash_id).where("hash_id in (?)", session[:shipment_products].keys)
      puts "--- loading inventaries ---"
      warehouse_products = WarehouseProduct.where("product_id in (?)", products.map(&:id)).where(describes_total_stock: false)

      session[:shipment_products].keys.each do |k|
        session[:shipment_products][k].delete("name")
        session[:shipment_products][k].keys.each do |s_k|
          product_id = 0
          products.each do |p|
            if p.hash_id == k
              product_id = p.id
              break
            end
          end # products.each #

          hash = session[:shipment_products][k][s_k]
          product_expiration_date = hash["expiration_date"]

          if params[:shipment] and params[:shipment][:type] == "TRANSFER"
            product_exist = false
            warehouse_products.each do |wp|
              if wp.product_id == product_id and wp.batch == hash["batch"]
                product_expiration_date = wp.expiration_date
                product_exist = true
                break
              elsif wp.product_id != product_id and wp.batch == hash["batch"]
                success = false
                puts "--- Raising a rollback cuz cant repeat batch! ---"
                raise ActiveRecord::Rollback, "Can't repeat batch!"
              end # if wp.product_id == product_id and ...#
            end # warehouse_products.each #
          end

          # Raise an exception if the product doesn't exist and the shipment is a transfer #
          if params[:shipment] and params[:shipment][:type] == "TRANSFER" and !product_exist
            success = false
            puts "--- Raising a rollback cuz product didn't exist ---"
            raise ActiveRecord::Rollback, "Call tech support!"
          end

          shipment.save if shipment.id == nil

          puts "--- creating new detail for the shipment ---"
          detail = ShipmentDetail.create(shipment_id: shipment.id,
          product_id: product_id, quantity: hash["quantity"], batch: hash["batch"],
          expiration_date: product_expiration_date)

          if shipment.shipment_type == "TRANSFER"
            puts "--- updating full stock descriptor and batch descriptor ---"
            master_product = WarehouseProduct.where(warehouse_id: warehouse.id,
                product_id: product_id, describes_total_stock: true).take

            product = WarehouseProduct.where(
                warehouse_id: warehouse.id, product_id: product_id,
                batch: hash["batch"]).take

            product.update_attributes(existence: (product.existence - hash["quantity"].to_i))
            master_product.update_attributes(existence: (master_product.existence - hash["quantity"].to_i))
          end # if params["shipment_type"] == "TRANSFER" #

        end # session[:shipment_products][k].keys.each #
      end # session[:shipment_products].keys.each #

      session[:shipment_products] = nil if success

    end if !session[:shipment_products].blank? #transaction end#

    flash[:success] = "Envío registrado!" if success
    flash[:danger] = "Ocurrió un error al guardar el envío verifica que los datos introducidos como lotes y fechas de caducidad sean correctos." if !success
    if shipment.shipment_type == "TRANSFER"
      redirect_to admin_warehouse_products_path(params[:warehouse_id])
    else
      redirect_to admin_chief_warehouse_products_path(params[:warehouse_id])
    end
  end

  def destroy_shipment
    authorization_result = @current_user.is_authorized?(@@category, "DELETE_SHIPMENTS")
    return if !process_authorization_result(authorization_result)

    @shipment = Shipment.find(params[:id])
    @details = @shipment.Details
    success = false
    ActiveRecord::Base.transaction do
      if @shipment.shipment_type == "TRANSFER"
        @details.each do |d|
          master_product = WarehouseProduct.where(warehouse_id: @shipment.origin_warehouse_id,
          product_id: d.product_id, describes_total_stock: true).take

          product = WarehouseProduct.where(warehouse_id: @shipment.origin_warehouse_id,
          product_id: d.product_id, describes_total_stock: false, batch: d.batch,
          expiration_date: d.expiration_date).take

          master_product.update_attributes(existence: master_product.existence + d.quantity)
          product.update_attributes(existence: product.existence + d.quantity)

        end # @details.each do #
      end # if @shipment.shipment_type == "TRANSFER" #

      @details.destroy_all
      @shipment.destroy
      success = true
    end

    flash[:success] = "Envío eliminado." if success
    flash[:danger] = "Ocurrió un error al eliminar el envío." if !success
    redirect_to admin_chief_shipments_path(params[:warehouse_id])
  end

  def shipments
    authorization_result = @current_user.is_authorized?(@@manager_category, "RECEIVE_SHIPMENTS")
    return if !process_authorization_result(authorization_result)

    @warehouse = @current_user.Warehouse
    @shipments = @warehouse.IncomingShipments.includes(:Chief, :Worker, :OriginWarehouse).order(:created_at => :desc).paginate(page: params[:page], per_page: 20)
  end

  def shipment_details
    authorization_result = @current_user.is_authorized?(@@manager_category, "RECEIVE_SHIPMENTS")
    return if !process_authorization_result(authorization_result)

    @shipment = Shipment.find(params[:id])
    @warehouse = @shipment.TargetWarehouse
    @details = @shipment.Details.includes(:Product)

    if @shipment.got_safe_to_destination == false
      @report = @shipment.DifferenceReport
      @report_details = @report.Details
    end
  end

  def receive_complete_shipment
    authorization_result = @current_user.is_authorized?(@@manager_category, "RECEIVE_SHIPMENTS")
    return if !process_authorization_result(authorization_result)

    shipment = Shipment.find(params[:id])
    if shipment.reviewed == false
      warehouse = Warehouse.find_by(hash_id: params[:warehouse_id])
      saved = update_stock_from_shipment(warehouse, shipment)
    end

    flash[:success] = "Se añadieron los productos al stock actual!" if saved
    flash[:danger] = "Ocurrió un error inesperado, por favor intentelo de nuevo" if !saved
    redirect_to admin_shipments_path(warehouse.hash_id)
  end

  def chief_shipments
    authorization_result = @current_user.is_authorized?(@@category, "SHOW_SHIPMENTS")
    return if !process_authorization_result(authorization_result)

    @warehouse = Warehouse.find_by(hash_id: params[:warehouse_id])
    @shipments = @warehouse.IncomingShipments.includes(:Chief, :Worker, :OriginWarehouse).order(:created_at => :desc).paginate(page: params[:page], per_page: 20)

    # determine the actions the user can do, so we can display them in screen #
    @actions = {"DELETE_SHIPMENTS"=>false}
    if !@current_user.is_admin
      @user_permissions.each do |p|
        # see if the permission category is equal to the one we need in these controller #
        if p.category == @@category and p.name == "DELETE_SHIPMENTS"
          @actions[p.name]=true
        end # if p.category == @@category #
      end # @user_permissions.each end #
    else
      @actions = {"DELETE_SHIPMENTS"=>true}
    end # if !@current_user.is_admin end #
  end

  def chief_shipment_details
    authorization_result = @current_user.is_authorized?(@@category, "SHOW_SHIPMENTS")
    return if !process_authorization_result(authorization_result)

    @shipment = Shipment.find(params[:id])
    @warehouse = @shipment.TargetWarehouse
    @details = @shipment.Details.includes(:Product)

    if @shipment.got_safe_to_destination == false
      @report = @shipment.DifferenceReport
      @report_details = @report.Details
    end

    # determine the actions the user can do, so we can display them in screen #
    @actions = {"REJECT_SHIPMENT_STOCK"=>false}
    if !@current_user.is_admin
      @user_permissions.each do |p|
        # see if the permission category is equal to the one we need in these controller #
        if p.category == @@category and p.name == "REJECT_SHIPMENT_STOCK"
          @actions[p.name]=true
        end # if p.category == @@category #
      end # @user_permissions.each end #
    else
      @actions = {"REJECT_SHIPMENT_STOCK"=>true}
    end # if !@current_user.is_admin end #
  end

  def add_report_quantity_to_stock
    authorization_result = @current_user.is_authorized?(@@category, "REJECT_SHIPMENT_STOCK")
    return if !process_authorization_result(authorization_result)

    shipment = Shipment.find(params[:id])
    if shipment.reviewed == false
      warehouse = Warehouse.find_by(hash_id: params[:warehouse_id])
      report = shipment.DifferenceReport

      saved = update_stock_from_shipment(warehouse, shipment, report)
    end

    flash[:success] = "Se añadieron los productos al stock actual!" if saved
    flash[:danger] = "Ocurrió un error inesperado, por favor intentelo de nuevo" if !saved
    redirect_to admin_warehouse_products_path(warehouse.hash_id)
  end

  def create_difference_report
    authorization_result = @current_user.is_authorized?(@@manager_category, "RECEIVE_SHIPMENTS")
    return if !process_authorization_result(authorization_result)

    @warehouse = Warehouse.find_by(hash_id: params[:warehouse_id])
    @shipment = Shipment.find(params[:id])
    @saved = false

    ActiveRecord::Base.transaction do
      @shipment.update_attributes(:got_safe_to_destination => false, :worker_id => @current_user.id, :reviewed => false)
      @report = ShipmentDifferenceReport.create(shipment_id: @shipment.id,
      worker_id: @current_user.id, observations: params[:observations])

      params.each do |p|
        if p[0].include?("difference_")
          string_id = p[0].split("_")[1]

          ShipmentDifferenceReportDetail.create(difference_report_id: @report.id,
          shipment_detail_id: string_id, difference: p[1]) if !p[1].blank?
        end
      end
      @saved = true
    end # transaction end #

    flash[:success] = "Reporte enviado a los jefes de almacén..." if @saved
    flash[:danger] = "Ocurrió un error inesperado..." if !@saved
    redirect_to admin_shipments_path(params[:warehouse_id])
  end

  def update_min_stock
    authorization_result = @current_user.is_authorized?(@@category, "UPDATE_MIN_STOCK")
    return if !process_authorization_result(authorization_result)

    if params[:warehouse_product][:min_stock].to_i > 0
      w_product = WarehouseProduct.joins(:Warehouse).joins(:Product)
            .where(
                  warehouses: {hash_id: params[:warehouse_id]},
                  products: {hash_id: params[:id]},
                  describes_total_stock: true).take

      w_product.min_stock = params[:warehouse_product][:min_stock].to_i if params[:warehouse_product][:min_stock]
      w_product.save
    end

    respond_to do |format|
      format.js { render :update_min_stock, :layout => false }
    end
  end

  def print_qr
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @product = Product.find_by(hash_id: params[:product_qr][:product])
    if @product.blank?
      flash[:danger] = "No se encontró el producto con clave #{params[:product_qr][:product]}."
      redirect_to admin_chief_warehouse_products_path(params[:product_qr][:warehouse])
      return
    end

    @batch = params[:product_qr][:batch]
    @expiration_date = params[:product_qr][:expiration_date]

    @qr = RQRCode::QRCode.new( "#{@product.name}|#{@batch}")

    render :print_qr, layout: false
  end

  private
    def authenticate
      if !logged_in? or session[:user_type != 'w']
        redirect_to controller: '/sessions', action: :new
        return false
      end

      return if @current_user.is_admin

      @curr_permission = @current_user.Permission
      if !@curr_permission.warehouses
        redirect_to admin_welcome_path
        return false
      end

      return true
    end

    def authenticate_chief
      if !logged_in? or session[:user_type != 'w']
        redirect_to controller: '/sessions', action: :new
        return
      end

      return if @current_user.is_admin

      @curr_permission = @current_user.Permission
      if !@curr_permission.warehouse_chief
        redirect_to admin_welcome_path
        return
      end
    end

    def update_stock_from_shipment(warehouse, shipment, report = nil)
      puts "--- inside update stock from shipment ---"
      details = shipment.Details
      report_details = report.Details if !report.nil?

      product_id = details[0].product_id
      total = 0
      saved = false
      ids_are_different = false
      ActiveRecord::Base.transaction do
        puts "--- iterating details ---"
        details.each do |d|
          has_a_report = false
          quantity_to_add = 0

          if product_id == d.product_id
            puts "--- ids are the same ---"
            ids_are_different = false
          else
            puts "--- ids are different ---"
            ids_are_different = true
          end

          if ids_are_different
            puts "--- product changed adding the quantities to full stock descriptor ---"
            update_principal_warehouse_product_stock(warehouse.id, product_id, total)
            product_id = d.product_id
            total = 0
            quantity_to_add = 0
          end # if product_id == d.product_id else end #

          if !report.nil?
            puts "--- there is a report going to iterate it ---"
            report_details.each do |r_d|
              if r_d.shipment_detail_id == d.id
                puts "--- found a complain adding difference: #{r_d.difference} ---"
                has_a_report = true
                quantity_to_add = r_d.difference
                total += r_d.difference
                break
              end
            end # report_details.each end #
            if !has_a_report
              puts "--- didn't get a complain for current product in the report adding normal quantity: #{d.quantity} ---"
              total += d.quantity
              quantity_to_add = d.quantity
            end
          else
            total += d.quantity
            quantity_to_add = d.quantity
          end # if report end #

          puts "--- creating new descriptor with id: #{product_id}, and existence: #{quantity_to_add} ---"
          existing_batch = WarehouseProduct.where(batch: d.batch, warehouse_id: warehouse.id, product_id: product_id).take
          if !existing_batch.nil?
            existing_batch.update_attributes(existence: existing_batch.existence + quantity_to_add)
          else
            WarehouseProduct.create(warehouse_id: warehouse.id, product_id: product_id,
                  describes_total_stock: false, hash_id: random_hash_id(12).upcase,
                  existence: quantity_to_add, batch: d.batch, expiration_date: d.expiration_date)
          end

        end # details.each end #

        update_principal_warehouse_product_stock(warehouse.id, product_id, total)

        shipment.update_attributes(:got_safe_to_destination => true, :worker_id => @current_user.id, :reviewed => true) if !report
        shipment.update_attributes(:reviewed => true) if report
        saved = true
      end # transaction end #

      return saved
    end

    def update_principal_warehouse_product_stock(warehouse_id, product_id, total)
      puts "--- updating total descriptor for warehouse: #{warehouse_id} and product: #{product_id}"
      w = WarehouseProduct.where(warehouse_id: warehouse_id, product_id: product_id,
        describes_total_stock: true).take
      puts "--- current_existence: w.existence, adding: #{total}"
      w.update_attributes(existence: w.existence + total)
    end

end
