class Admin::ParcelsController < AdminController

  def index
    deny_access! and return unless @current_user.has_permission_category?('parcels')

    @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
    @parcels = @warehouse.Parcels
  end

  def new
    deny_access! and return unless @current_user.has_permission?('parcels@create')

    @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
    @parcel = Parcel.new
  end

  def create
    deny_access! and return unless @current_user.has_permission?('parcels@create')

    @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])

    @parcel = Parcel.new(parcel_params)
    @parcel.warehouse_id = @warehouse.id
    if @parcel.save
      flash[:success] = "Paquetería creada..."
      redirect_to admin_warehouse_parcels_path(@warehouse.hash_id)
    else
      flash.now[:danger] = "Ocurrió un error al guardar la paquetería"
      render :new
    end
  end

  def edit
    deny_access! and return unless @current_user.has_permission?('parcels@update')

    @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
    @parcel = Parcel.find(params[:id])
  end

  def update
    deny_access! and return unless @current_user.has_permission?('parcels@update')

    @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
    @parcel = Parcel.find(params[:id])

    if @parcel.update_attributes(parcel_params)
      flash[:success] = "Paquetería actualizada..."
      redirect_to admin_warehouse_parcels_path(@warehouse.hash_id)
    else
      flash.now[:danger] = "Ocurrió un error al guardar la paquetería"
      render :edit
    end
  end

  def destroy
    deny_access! and return unless @current_user.has_permission?('parcels@delete')

    @parcel = Parcel.find(params[:id])
    if @parcel.destroy
      flash[:success] = "Paquetería eliminada..."
    else
      flash[:info] = "Ocurrió un error inesperado..."
    end

    redirect_to admin_warehouse_parcels_path(params[:warehouse_id])
  end

  private
    def parcel_params
      params.require(:parcel).permit(:parcel_name, :delivery_time, :image, :tracking_url)
    end

end
