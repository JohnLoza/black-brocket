class Admin::WarehouseRegionsController < AdminController

  def index
    deny_access! and return unless @current_user.has_permission?('warehouses@update_regions')
    @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
    @regions = @warehouse.Regions
    @states = State.where(warehouse_id: nil).order_by_name
  end

  def create
    deny_access! and return unless @current_user.has_permission?('warehouses@update_regions')

    @saved = false
    @state = State.find_by!(id: params[:state_id])

    if @state.warehouse_id == nil
      @state.update_attribute(:warehouse_id, params[:warehouse_region][:warehouse_id])
      @saved = true
    end

    respond_to do |format|
      format.js { render :create, :layout => false }
    end
  end

  def destroy
    deny_access! and return unless @current_user.has_permission?('warehouses@update_regions')

    @deleted = false
    @state = State.find_by!(id: params[:id])
    warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])

    if @state.warehouse_id == warehouse.id
      @state.update_attribute(:warehouse_id, nil)
      @deleted = true
    end

    respond_to do |format|
      format.js { render :destroy, :layout => false }
    end
  end

end
