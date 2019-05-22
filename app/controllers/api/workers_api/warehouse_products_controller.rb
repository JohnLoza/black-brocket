class Api::WorkersApi::WarehouseProductsController < ApiController
  before_action do
    authenticate_user!(:site_worker)
  end

  def index
    warehouse_products = @current_user.Warehouse.Products.joins(:Product)
      .where(describes_total_stock: true, products: {deleted_at: nil})
      .order("products.name asc").paginate(page: params[:page], per_page: 20).includes(:Product)
    data = Array.new
    warehouse_products.each do |w_p|
      data << {hash_id: w_p.Product.hash_id, name: w_p.Product.name, existence: w_p.existence, min_stock: w_p.min_stock}
    end

    render status: 200, json: {success: true, info: "DATA_RETURNED", data: data}
  end

  def existence
    render status: 200, json: {success: false, info: "BATCH_MUST_BE_PRESENT"} and return unless params[:batch]

    wp = @current_user.Warehouse.Products.where(batch: params[:batch]).take
    render status: 200, json: {success: false, info: "WAREHOUSE_PRODUCT_NOT_FOUND"} and return unless wp

    data = { product_id: wp.product_id, batch: wp.batch, existence: wp.existence }

    render status: 200, json: {success: true, info: "DATA_RETURNED", data: data}
  end

  def create_inventory_report
    render status: 200, json: {success: false, info: "REPORT_DETAILS_REQUIRED"} and return unless params[:report]

    inventory_report = InventoryReport.new(inventory_report_params)
    inventory_report.worker_id = @current_user.id
    inventory_report.warehouse_id = @current_user.warehouse_id

    worker = SiteWorker.joins(:Permissions)
      .where(warehouse_id: @current_user.warehouse_id)
      .where(permissions: {category: 'WAREHOUSE_MANAGER'}).take

    render status: 200, json: {success: false, info: "NO_ONE_TO_REPORT_AT"} and return unless worker

    if inventory_report.save
      Notification.create(worker_id: worker.id, icon: "fa fa-file-text-o", description: "Nuevo reporte de inventario", 
        url: "/admin/warehouse/#{@current_user.Warehouse.hash_id}/inventory_report/#{inventory_report.id}")

      render status: 200, json: {success: true, info: "SAVED"}
    else
      render status: 200, json: {success: false, info: "NOT_SAVED"}
    end
  end

  private
    def inventory_report_params
      params.require(:report).permit(:product_id, :batch, :description, :comment)
    end
end
