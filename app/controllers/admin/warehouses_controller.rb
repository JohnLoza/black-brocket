class Admin::WarehousesController < AdminController

  def index
    unless @current_user.has_permission_category?('warehouses') or
           @current_user.has_permission_category?('parcels') or
           @current_user.has_permission_category?('warehouse_products') or
           @current_user.has_permission_category?('warehouse_manager')
      deny_access! and return
    end

    @warehouses = Warehouse.active.search(key_words: search_params, fields: ['hash_id', 'name'])
      .order_by_name.paginate(page: params[:page], per_page: 25).includes(City: :State)
  end

  def show
    deny_access! and return unless @current_user.has_permission?('warehouses@show')
    @warehouse = Warehouse.find_by!(hash_id: params[:id])
  end

  def new
    deny_access! and return unless @current_user.has_permission?('warehouses@create')

    @warehouse = Warehouse.new
    @states = State.order_by_name
    @cities = Array.new
  end

  def create
    deny_access! and return unless @current_user.has_permission?('warehouses@create')

    @warehouse = Warehouse.new(warehouse_params)
    @warehouse.city_id = params[:city_id]

    ActiveRecord::Base.transaction do
      if @warehouse.save
        @warehouse.update_attribute(:hash_id, generateAlphKey("A", @warehouse.id))
        Product.all.each do |p|
          WarehouseProduct.create(warehouse_id: @warehouse.id,
            describes_total_stock: true, product_id: p.id, existence: 0,
            min_stock: 50, hash_id: random_hash_id(12).upcase)
        end
        flash[:success] = "Almacén creado"
        redirect_to admin_warehouses_path
      else
        @states = State.order_by_name
        @cities = City.where(state_id: @state_id)
        render :new
      end # if @warehouse.save #
    end # Transaction #
  end

  def edit
    unless @current_user.has_permission?('warehouses@update_warehouse_data') or
           @current_user.has_permission?('warehouses@update_wholesale') or
           @current_user.has_permission?('warehouses@update_shipping_cost')
      deny_access! and return
    end

    @warehouse = Warehouse.find_by!(hash_id: params[:id])
    params[:city_id] = @warehouse.city_id
    params[:state_id] = @warehouse.City.state_id
    @states = State.order_by_name
    @cities = City.where(state_id: params[:state_id]).order_by_name
  end

  def update
    unless @current_user.has_permission?('warehouses@update_warehouse_data') or
           @current_user.has_permission?('warehouses@update_wholesale') or
           @current_user.has_permission?('warehouses@update_shipping_cost')
      deny_access! and return
    end

    @warehouse = Warehouse.find_by!(hash_id: params[:id])
    @warehouse.city_id = params[:city_id]

    if @warehouse.update_attributes(warehouse_params)
      redirect_to admin_warehouses_path, flash: {success: 'Almacén actualizado' }
    else
      @states = State.order_by_name
      @cities = City.where(state_id: params[:state_id]).order_by_name
      render :edit
    end
  end

  def destroy
    deny_access! and return unless @current_user.has_permission?('warehouses@delete')

    @warehouse = Warehouse.find_by!(hash_id: params[:id])
    @warehouse.destroy
    redirect_to admin_warehouses_path, flash: {success: 'Almacén eliminado' }
  end

  def batch_search
    deny_access! and return unless @current_user.has_permission?('warehouse_products@batch_search')

    if params[:batch]
      @products_in_warehouse = WarehouseProduct.where(batch: params[:batch]).includes(:Warehouse)

      @inventory_reports = InventoryReport.where(batch: params[:batch]).includes(:Worker)

      @products_to_ship = OrderProductShipmentDetail.joins(:Order)
        .where(orders: {state: ["BATCHES_CAPTURED", "INSPECTIONED"]})
        .where(batch: params[:batch]).includes(Order: :Client)

      @products_shipped = OrderProductShipmentDetail.joins(:Order)
        .where(orders: {state: ["SENT", "DELIVERED"]})
        .where(batch: params[:batch]).includes(Order: :Client)
    end
  end

  def inventory
    deny_access! and return unless @current_user.has_permission?('warehouse_products@inventory')

    @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])

    @products_in_stock = @warehouse.Products.joins(:Product).where(products: {deleted_at: nil})
      .where(warehouse_id: @warehouse.id, describes_total_stock: true)
      .order(product_id: :asc).includes(:Product)

    @products_no_pay = OrderDetail.select("product_id, sum(quantity) as sum_quantity").joins(:Order)
      .where(orders: {state: ["WAITING_FOR_PAYMENT", "PAYMENT_DEPOSITED", "PAYMENT_REJECTED"], warehouse_id: @warehouse.id}).group(:product_id)

    @products_paid = OrderDetail.select("product_id, sum(quantity) as sum_quantity").joins(:Order)
      .where(orders: {state: ["PAYMENT_ACCEPTED", "BATCHES_CAPTURED"], warehouse_id: @warehouse.id}).group(:product_id)

    @complement = OrderDetail.joins(:Order)
      .where(orders: {state: ["INSPECTIONED"], warehouse_id: @warehouse.id}).includes(:Order)

    render :inventory, layout: false
  end

  def inventory_reports
    @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
    @reports = InventoryReport.where(warehouse_id: @warehouse.id).order(created_at: :desc)
      .paginate(page: params[:page], per_page: 25)
  end

  def inventory_report_details
    @report = InventoryReport.find(params[:id])
    @warehouse = @report.Warehouse

    unless @current_user.warehouse_id == @warehouse.id or @current_user.is_admin
      deny_access! and return 
    end

    if params[:notification].present?
      notification = Notification.find(params[:notification])
      notification.update_attributes(seen: true) unless notification.seen
    end
  end

  def inventory_report_solved
    @report = InventoryReport.find(params[:id])
    @report.update_attributes(done: :true)
    flash[:success] = 'Reporte guardado exitosamente.'
    redirect_to admin_inventory_reports_path
  end

  private
    def warehouse_params
      params.require(:warehouse).permit(:name, :address, :telephone, :shipping_cost, :wholesale)
    end
end
