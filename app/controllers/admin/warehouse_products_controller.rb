class Admin::WarehouseProductsController < AdminController

  def index
    if @current_user.has_permission_category?("warehouse_products")
      redirect_to admin_chief_warehouse_products_path(params[:warehouse_id]) and return
    elsif !@current_user.has_permission_category?("warehouse_manager")
      deny_access! and return
    end

    @warehouse = @current_user.Warehouse

    @products = @warehouse.Products.joins(:Product)
      .where(describes_total_stock: true, products: {deleted_at: nil})
      .includes(:Product).order("products.name asc").paginate(page: params[:page], per_page: 20)

    if @current_user.has_permission?("warehouse_manager@transfer_mercancy")
      @warehouses = Warehouse.active.where.not(id: @current_user.warehouse_id)
    end
  end # def index #

  def stock_details
    unless @current_user.has_permission_category?("warehouse_manager") or
      @current_user.has_permission_category?("warehouse_products")
      deny_access! and return 
    end

    @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
    @product = Product.find(params[:id])
    @stock_details = @warehouse.Products.where(product_id: params[:id], describes_total_stock: false)
  end # def stock_details #

  def update_stock
    deny_access! and return unless @current_user.has_permission?("warehouse_products@update_stock")

    warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
    product = Product.find(params[:id])

    master_detail = WarehouseProduct.where(warehouse_id: warehouse.id,
      product_id: product.id, describes_total_stock: true).take

    detail = WarehouseProduct.where(warehouse_id: warehouse.id,
      batch: params[:warehouse_product][:batch],
      product_id: product.id, describes_total_stock: false,
      expiration_date: params[:warehouse_product][:expiration_date]).take

    difference = detail.existence - params[:warehouse_product][:existence].to_i
    begin
      ActiveRecord::Base.transaction do
        master_detail.withdraw(difference)
        detail.withdraw(difference)
      end
    rescue ActiveRecord::RangeError
      flash[:info] = "Stock resultante menor a 0"
    end

    flash[:success] = "Stock modificado" unless flash[:info].present?
    redirect_to admin_warehouse_products_stock_details_path(warehouse.hash_id, product.id)
  end

  def chief_index
    deny_access! and return unless @current_user.has_permission_category?("warehouse_products")

    @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])

    if @current_user.has_permission?("warehouse_products@show")
      @products = @warehouse.Products.joins(:Product)
        .where(describes_total_stock: true, products: {deleted_at: nil})
        .order("products.name asc").paginate(page: params[:page], per_page: 20).includes(:Product)
    end
  end

  def prepare_product_for_shipment
    unless @current_user.has_permission?("warehouse_manager@transfer_mercancy") or
      @current_user.has_permission?("warehouse_products@create_shipments")
      deny_access! and return
    end

    session[:shipment_products] = Hash.new if session[:shipment_products].nil?
    session[:shipment_products][:warehouse] = params[:warehouse_id] unless session[:shipment_products][:warehouse].present?

    @hash = Hash.new
    @hash_id = Utils.new_alphanumeric_token(9).upcase

    @hash[params[:id]] = {"name" => params[:warehouse_product][:name],
      @hash_id => {"quantity" => params[:warehouse_product][:quantity],
        "batch" => params[:warehouse_product][:batch],
        "expiration_date" => params[:warehouse_product][:expiration_date]}}

    session[:shipment_products][params[:id]] = {}
    session[:shipment_products][params[:id]][@hash_id] = @hash[params[:id]][@hash_id]
    session[:shipment_products][params[:id]][:name] = params[:warehouse_product][:name]

    respond_to do |format|
      format.js { render :prepare_product_for_shipment, layout: false }
    end
  end

  def discard_shipment_preparation
    unless @current_user.has_permission?("warehouse_manager@transfer_mercancy") or
      @current_user.has_permission?("warehouse_products@create_shipments")
      deny_access! and return
    end
    # TODO refactor
    @k = nil
    session[:shipment_products].keys.each do |k|
      next if k == "warehouse"
      has_the_target = session[:shipment_products][k].has_key?(params[:id])
      if has_the_target
        session[:shipment_products][k].delete(params[:id])
        @k = k
      end
    end

    if @k and session[:shipment_products][@k].keys.size <= 1
      session[:shipment_products].delete(@k)
      @remove_container = true
    end

    respond_to do |format|
      format.js { render :discard_shipment_preparation, layout: false }
    end
  end

  def create_shipment
    # TODO refactor
    unless @current_user.has_permission?("warehouse_manager@transfer_mercancy") or
      @current_user.has_permission?("warehouse_products@create_shipments")
      deny_access! and return
    end
    deny_access! and return unless session[:shipment_products].present?
    warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
    shipment = Shipment.new(shipment_params)

    ActiveRecord::Base.transaction do
      shipment.save!
      session[:shipment_products].delete("warehouse")
      products = Product.select(:id, :hash_id).where("id in (?)", session[:shipment_products].keys)

      # iterate the shipment details
      session[:shipment_products].keys.each do |product_id|

        session[:shipment_products][product_id].delete("name")
        # search for the product id that matches this details
        session[:shipment_products][product_id].keys.each do |hash|

          product_info = session[:shipment_products][product_id][hash]
          product_expiration_date = product_info["expiration_date"]
          current_detail = ShipmentDetail.new(shipment_id: shipment.id, product_id: product_id, 
            quantity: product_info["quantity"], batch: product_info["batch"], 
            expiration_date: product_info["expiration_date"], type: shipment.shipment_type, 
            target_warehouse_id: shipment.target_warehouse_id, origin_warehouse_id: shipment.origin_warehouse_id)
          current_detail.save!

        end # session[:shipment_products][product_id].keys.each #

      end # session[:shipment_products].keys.each #

      session.delete(:shipment_products)
      flash[:success] = "Envío registrado!"
    end
    
    flash[:info] = "Ocurrió un error al guardar el envío" unless flash[:success].present?
    if shipment.shipment_type == "TRANSFER"
      redirect_to admin_warehouse_products_path(params[:warehouse_id])
    else
      redirect_to admin_chief_warehouse_products_path(params[:warehouse_id])
    end
  end

  def destroy_shipment
    deny_access! and return unless @current_user.has_permission?("warehouse_products@delete_shipments")

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
    deny_access! and return unless @current_user.has_permission?("warehouse_manager@receive_shipments")

    @warehouse = @current_user.Warehouse
    @shipments = @warehouse.IncomingShipments.includes(:Chief, :Worker, :OriginWarehouse)
      .order(created_at: :desc).paginate(page: params[:page], per_page: 20)
  end
  
  def shipment_details
    deny_access! and return unless @current_user.has_permission?("warehouse_manager@receive_shipments")

    @shipment = Shipment.find(params[:id])
    @warehouse = @shipment.TargetWarehouse
    @details = @shipment.Details.includes(:Product)

    if @shipment.got_safe_to_destination == false
      @report = @shipment.DifferenceReport
      @report_details = @report.Details
    end
  end

  def receive_complete_shipment
    deny_access! and return unless @current_user.has_permission?("warehouse_manager@receive_shipments")
    shipment = Shipment.find(params[:id])
    render_404 and return if shipment.reviewed

    warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
    update_stock_from_shipment(warehouse, shipment)
    
    flash[:success] = "Se añadieron los productos al stock actual!"
    redirect_to admin_shipments_path(warehouse.hash_id)
  end

  def chief_shipments
    deny_access! and return unless @current_user.has_permission?("warehouse_products@show_shipments")

    @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
    @shipments = @warehouse.IncomingShipments.includes(:Chief, :Worker, :OriginWarehouse)
      .order(created_at: :desc).paginate(page: params[:page], per_page: 20)
  end

  def chief_shipment_details
    deny_access! and return unless @current_user.has_permission?("warehouse_products@show_shipments")

    @shipment = Shipment.find(params[:id])
    @warehouse = @shipment.TargetWarehouse
    @details = @shipment.Details.includes(:Product)

    if @shipment.got_safe_to_destination == false
      @report = @shipment.DifferenceReport
      @report_details = @report.Details
    end
  end

  def add_report_quantity_to_stock
    deny_access! and return unless @current_user.has_permission?("warehouse_products@reject_shipment_stock")
    shipment = Shipment.find(params[:id])
    render_404 and return if shipment.reviewed
    
    warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
    report = shipment.DifferenceReport
    update_stock_from_shipment(warehouse, shipment, report)

    flash[:success] = "Se añadieron los productos al stock actual!"
    redirect_to admin_warehouse_products_path(warehouse.hash_id)
  end

  def create_difference_report
    deny_access! and return unless @current_user.has_permission?("warehouse_manager@receive_shipments")

    @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
    @shipment = Shipment.find(params[:id])

    ActiveRecord::Base.transaction do
      @shipment.update_attributes(got_safe_to_destination: false,
        worker_id: @current_user.id, reviewed: false)
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
    deny_access! and return unless @current_user.has_permission?("warehouse_products@update_min_stock")

    if params[:warehouse_product][:min_stock].to_i > 0
      w_product = WarehouseProduct.joins(:Warehouse).joins(:Product)
        .where(warehouses: {hash_id: params[:warehouse_id]},
          products: {hash_id: params[:id]}, describes_total_stock: true).take

      raise ActiveRecord::RecordNotFound unless w_product
      w_product.update_attributes(min_stock: params[:warehouse_product][:min_stock])
    end

    respond_to do |format|
      format.js { render :update_min_stock, layout: false }
    end
  end

  def print_qr
    unless @current_user.has_permission_category?("warehouse_products") or
      @current_user.has_permission_category?("warehouse_manager")
      deny_access! and return 
    end

    @product = Product.find_by!(hash_id: params[:product_qr][:product])
    @qr = RQRCode::QRCode.new( "#{@product.name}|#{params[:product_qr][:batch]}")

    render :print_qr, layout: false
  end

  private
    def update_stock_from_shipment(warehouse, shipment, report = nil)
      details = shipment.Details
      report_details = report.Details if report.present?
      ActiveRecord::Base.transaction do
        details.each do |detail|
          to_be_added = 0
          if report.present?
            report_details.each do |report_detail|
              # if the product of the current detail has a report #
              # use the quantity specified in the report #
              if report_detail.shipment_detail_id == detail.id
                to_be_added = report_detail.difference
              end
            end # report_details.each end #
            # if the product of the current details has no report #
            # use de shipment detail quantity #
            to_be_added = detail.quantity unless to_be_added.present?
          else # no report present use the shipment detail quantity #
            to_be_added = detail.quantity
          end # if report.present? end #

          update_product_stock(warehouse.id, detail, to_be_added)
        end
        shipment.update_attributes(got_safe_to_destination: true, worker_id: @current_user.id, reviewed: true) unless report.present?
        shipment.update_attributes(reviewed: true) if report
        return true
      end # ActiveRecord::Base.transaction #
    end

    def update_product_stock(warehouse_id, detail, to_be_added)
      existing_batch = WarehouseProduct.where(warehouse_id: warehouse_id, 
        product_id: detail.product_id, batch: detail.batch).take
      if existing_batch.present?
        existing_batch.supply(to_be_added)
      else
        WarehouseProduct.create(warehouse_id: warehouse_id, product_id: detail.product_id,
          describes_total_stock: false, hash_id: Utils.new_alphanumeric_token(9).upcase,
          existence: to_be_added, batch: detail.batch, expiration_date: detail.expiration_date)
      end
      total_descriptor = WarehouseProduct.where(warehouse_id: warehouse_id, 
        product_id: detail.product_id, describes_total_stock: true).take
      total_descriptor.supply(to_be_added)
    end

    def shipment_params
      params.require(:shipment).permit(:shipment_type, :chief_id, 
        :target_warehouse_id, :origin_warehouse_id)
    end

end
