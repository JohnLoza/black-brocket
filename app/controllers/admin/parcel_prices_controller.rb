class Admin::ParcelPricesController < AdminController
  before_action :verify_permissions

  def index
    @parcel = Parcel.find(params[:id])
    @prices = @parcel.Prices
  end

  def new
    @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
    @parcel = Parcel.find(params[:id])
    @price = ParcelPrice.new
  end

  def create
    @price = ParcelPrice.new(price_params)
    @price.parcel_id = params[:id]
    if @price.save
      flash[:success] = "Precio creado!"
      redirect_to admin_warehouse_parcel_parcel_prices_path(params[:warehouse_id], params[:id])
    else
      @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
      @parcel = Parcel.find(params[:id])
      flash.now[:danger] = "Ocurrió un error al guardar el precio"
      render :new
    end
  end

  def edit
    @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
    @parcel = Parcel.find(params[:parcel_id])
    @price = ParcelPrice.find(params[:id])
  end

  def update
    @price = ParcelPrice.find(params[:id])

    if @price.update_attributes(price_params)
      flash[:success] = "Precio Actualizado!"
      redirect_to admin_warehouse_parcel_parcel_prices_path(params[:warehouse_id], params[:parcel_id])
    else
      @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
      @parcel = Parcel.find(params[:parcel_id])
      flash.now[:danger] = "Ocurrió un error al guardar el precio"
      render :edit
    end
  end

  def destroy
    @price = ParcelPrice.find(params[:id])
    if @price.destroy
      flash[:success] = "Precio eliminado!"
    else
      flash[:info] = "Ocurrió un error inesperado"
    end

    redirect_to admin_warehouse_parcel_parcel_prices_path(params[:warehouse_id], params[:parcel_id])
  end

  private
    def price_params
      params.require(:parcel_price).permit(:max_weight, :price)
    end

    def verify_permissions
      deny_access! and return unless @current_user.has_permission?('parcels#update')
    end

end
