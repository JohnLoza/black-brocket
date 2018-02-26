class Admin::WarehouseRegionsController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_worker?
  layout "admin_layout.html.erb"

  @@category = "WAREHOUSES"

  def index
    authorization_result = @current_user.is_authorized?(@@category, "UPDATE_REGIONS")
    return if !process_authorization_result(authorization_result)

    @warehouse = Warehouse.find_by(hash_id: params[:warehouse_id])
    if @warehouse.nil?
      flash[:info] = "No se encontró el almacén con clave: #{params[:warehouse_id]}"
      redirect_to admin_warehouses_path
      return
    end

    @regions = @warehouse.Regions

    @states = State.where(warehouse_id: nil).order(:name)
  end

  def create
    authorization_result = @current_user.is_authorized?(@@category, "UPDATE_REGIONS")
    return if !process_authorization_result(authorization_result)

    @saved = false
    @state = State.find_by(id: params[:state_id])
    if !@state.nil?

      if @state.warehouse_id == nil
        puts "--- the state is free to be taken, updating it ---"
        @state.update_attribute(:warehouse_id, params[:warehouse_region][:warehouse_id])
        @saved = true
      end

    end # if @state.nil? #

    respond_to do |format|
      format.js { render :create, :layout => false }
    end
  end

  def destroy
    authorization_result = @current_user.is_authorized?(@@category, "UPDATE_REGIONS")
    return if !process_authorization_result(authorization_result)

    @deleted = false
    @state = State.find_by(id: params[:id])
    if !@state.nil?
      warehouse = Warehouse.find_by(hash_id: params[:warehouse_id])

      if !warehouse.nil?
        if @state.warehouse_id == warehouse.id
          @state.update_attribute(:warehouse_id, nil)
          @deleted = true
        end
      else
        puts "--- Warehouse with key: #{params[:warehouse_id]} not found ---"
      end # !warehouse.nil? #

    else
      puts "--- State with key: #{params[:id]} not found ---"
    end # if @state.nil? #

    respond_to do |format|
      format.js { render :destroy, :layout => false }
    end
  end

end
