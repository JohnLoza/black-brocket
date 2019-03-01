class Admin::WarehouseProductsController < AdminController

  def index
    if @current_user.has_permission_category?('warehouse_products')
      redirect_to admin_chief_warehouse_products_path(params[:warehouse_id]) and return
    elsif !@current_user.has_permission_category?('warehouse_manager')
      deny_access! and return
    end
    session[:shipment_products] = Hash.new if !session[:shipment_products]

    @warehouse = @current_user.Warehouse

    @products = @warehouse.Products.joins(:Product)
      .where(:describes_total_stock => true, products: {deleted_at: nil})
      .includes(:Product).order("products.name asc").paginate(page: params[:page], per_page: 20)

    if @current_user.has_permission?('warehouse_manager@transfer_mercancy')
      @warehouses = Warehouse.active.where.not(id: @current_user.warehouse_id)
    end
  end # def index #

  def stock_details
    deny_access! and return unless @current_user.has_permission?('warehouse_manager@update_stock')

    @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
    @product = Product.find(params[:id])
    @stock_details = @warehouse.Products.where(product_id: params[:id], describes_total_stock: false)
  end # def stock_details #

  def update_stock
    deny_access! and return unless @current_user.has_permission?('warehouse_manager@update_stock')

    warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
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
    flash[:info] = "Ocurrió un error al modificar el stock." if !success
    redirect_to admin_warehouse_products_stock_details_path(warehouse.hash_id, product.id)
  end

  def chief_index
    deny_access! and return unless @current_user.has_permission_category?('warehouse_products')
    session[:shipment_products] = Hash.new if !session[:shipment_products]

    @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])

    if @current_user.has_permission?('warehouse_products@show')
      @products = @warehouse.Products.joins(:Product)
        .where(:describes_total_stock => true, products: {deleted_at: nil})
        .order("products.name asc").paginate(page: params[:page], per_page: 20).includes(:Product)
    end
  end

  def prepare_product_for_shipment
    unless @current_user.has_permission?('warehouse_manager@transfer_mercancy') or
           @current_user.has_permission?('warehouse_products@create_shipments')
      deny_access! and return
    end

    session[:shipment_products] = Hash.new if session[:shipment_products].nil?
    session[:shipment_products][:warehouse] = params[:warehouse_id] unless session[:shipment_products][:warehouse].present?

    @hash = Hash.new
    @hash_id = random_hash_id(12).upcase

    @hash[params[:id]] = {"name" => params[:warehouse_product][:name],
            @hash_id => {"quantity" => params[:warehouse_product][:quantity],
                         "batch" => params[:warehouse_product][:batch],
                         "expiration_date" => params[:warehouse_product][:expiration_date]}}

    session[:shipment_products][params[:id]] = {}
    session[:shipment_products][params[:id]][@hash_id] = @hash[params[:id]][@hash_id]
    session[:shipment_products][params[:id]][:name] = params[:warehouse_product][:name]

    respond_to do |format|
      format.js { render :prepare_product_for_shipment, :layout => false }
    end
  end

  def discard_shipment_preparation
    unless @current_user.has_permission?('warehouse_manager@transfer_mercancy') or
           @current_user.has_permission?('warehouse_products@create_shipments')
      deny_access! and return
    end

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
    unless @current_user.has_permission?('warehouse_manager@transfer_mercancy') or
           @current_user.has_permission?('warehouse_products@create_shipments')
      deny_access! and return
    end
    deny_access! and return unless session[:shipment_products].present?

    warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])

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
      warehouse_products = WarehouseProduct.where("product_id in (?)",
        products.map(&:id)).where(describes_total_stock: false)

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
            raise ActiveRecord::Rollback, "Product doesnt exist and is needed for transfer"
          end

          success = false and break unless shipment.save
          puts "--- creating new detail for the shipment ---"
          detail = ShipmentDetail.new(shipment_id: shipment.id, product_id: product_id,
            quantity: hash["quantity"], batch: hash["batch"],
            expiration_date: product_expiration_date)
          success = false and break unless detail.save

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

    end

    flash[:success] = "Envío registrado!" if success
    flash[:info] = "Ocurrió un error al guardar el envío verifica que los datos introducidos como lotes y fechas de caducidad sean correctos." if !success
    if shipment.shipment_type == "TRANSFER"
      redirect_to admin_warehouse_products_path(params[:warehouse_id])
    else
      redirect_to admin_chief_warehouse_products_path(params[:warehouse_id])
    end
  end

  def destroy_shipment
    deny_access! and return unless @current_user.has_permission?('warehouse_products@delete_shipments')

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
    flash[:info] = "Ocurrió un error al eliminar el envío." if !success
    redirect_to admin_chief_shipments_path(params[:warehouse_id])
  end

  def shipments
    deny_access! and return unless @current_user.has_permission?('warehouse_manager@receive_shipments')

    @warehouse = @current_user.Warehouse
    @shipments = @warehouse.IncomingShipments.includes(:Chief, :Worker, :OriginWarehouse).order(:created_at => :desc).paginate(page: params[:page], per_page: 20)
  end

  def shipment_details
    deny_access! and return unless @current_user.has_permission?('warehouse_manager@receive_shipments')

    @shipment = Shipment.find(params[:id])
    @warehouse = @shipment.TargetWarehouse
    @details = @shipment.Details.includes(:Product)

    if @shipment.got_safe_to_destination == false
      @report = @shipment.DifferenceReport
      @report_details = @report.Details
    end
  end

  def receive_complete_shipment
    deny_access! and return unless @current_user.has_permission?('warehouse_manager@receive_shipments')

    shipment = Shipment.find(params[:id])
    if shipment.reviewed == false
      warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
      if update_stock_from_shipment(warehouse, shipment)
        flash[:success] = "Se añadieron los productos al stock actual!"
      else
        flash[:info] = "Ocurrió un error inesperado, por favor intentelo de nuevo"
      end
    end

    redirect_to admin_shipments_path(warehouse.hash_id)
  end

  def chief_shipments
    deny_access! and return unless @current_user.has_permission?('warehouse_products@show_shipments')

    @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
    @shipments = @warehouse.IncomingShipments.includes(:Chief, :Worker, :OriginWarehouse)
      .order(:created_at => :desc).paginate(page: params[:page], per_page: 20)
  end

  def chief_shipment_details
    deny_access! and return unless @current_user.has_permission?('warehouse_products@show_shipments')

    @shipment = Shipment.find(params[:id])
    @warehouse = @shipment.TargetWarehouse
    @details = @shipment.Details.includes(:Product)

    if @shipment.got_safe_to_destination == false
      @report = @shipment.DifferenceReport
      @report_details = @report.Details
    end
  end

  def add_report_quantity_to_stock
    deny_access! and return unless @current_user.has_permission?('warehouse_products@reject_shipment_stock')

    shipment = Shipment.find(params[:id])
    if shipment.reviewed == false
      warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
      report = shipment.DifferenceReport
      if update_stock_from_shipment(warehouse, shipment, report)
        flash[:success] = "Se añadieron los productos al stock actual!"
      else
        flash[:info] = "Ocurrió un error inesperado, por favor intentelo de nuevo"
      end
    end

    redirect_to admin_warehouse_products_path(warehouse.hash_id)
  end

  def create_difference_report
    deny_access! and return unless @current_user.has_permission?('warehouse_manager@receive_shipments')

    @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
    @shipment = Shipment.find(params[:id])

    ActiveRecord::Base.transaction do
      @shipment.update_attributes(:got_safe_to_destination => false,
        :worker_id => @current_user.id, :reviewed => false)
      @report = ShipmentDifferenceReport.create!(shipment_id: @shipment.id,
      worker_id: @current_user.id, observations: params[:observations])

      params.each do |p|
        if p.include?("difference_")
          string_id = p.split("_")[1]

          ShipmentDifferenceReportDetail.create!(difference_report_id: @report.id,
            shipment_detail_id: string_id, difference: params[p])
        end
      end
      flash[:success] = "Reporte enviado a los jefes de almacén..."
    end # transaction end #

    flash[:info] = "Ocurrió un error inesperado..." if flash.empty?
    redirect_to admin_shipments_path(params[:warehouse_id])
  end

  def update_min_stock
    deny_access! and return unless @current_user.has_permission?('warehouse_products@update_min_stock')

    if params[:warehouse_product][:min_stock].to_i > 0
      w_product = WarehouseProduct.joins(:Warehouse).joins(:Product)
            .where(
                  warehouses: {hash_id: params[:warehouse_id]},
                  products: {hash_id: params[:id]},
                  describes_total_stock: true).take

      raise ActiveRecord::RecordNotFound unless w_product
      w_product.update_attributes(min_stock: params[:warehouse_product][:min_stock])
    end

    respond_to do |format|
      format.js { render :update_min_stock, :layout => false }
    end
  end

  def print_qr
    deny_access! and return unless @current_user.has_permission_category?('warehouse_products')

    @product = Product.find_by!(hash_id: params[:product_qr][:product])
    @qr = RQRCode::QRCode.new( "#{@product.name}|#{params[:product_qr][:batch]}")

    render :print_qr, layout: false
  end

  private
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
