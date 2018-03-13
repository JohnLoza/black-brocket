class Admin::ParcelsController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_worker?
  layout "admin_layout.html.erb"

  @@category = "PARCELS"

  def index
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @warehouse = Warehouse.find_by!(hash_id: params[:id])
    @parcels = @warehouse.Parcels

    # determine the actions the user can do, so we can display them in screen #
    @actions = {"SHOW"=>false,"CREATE"=>false,"DELETE"=>false,"UPDATE"=>false}
    if !@current_user.is_admin
      @user_permissions.each do |p|
        # see if the permission category is equal to the one we need in these controller #
        if p.category == @@category
          @actions[p.name]=true
        end # if p.category == @@category #
      end # @user_permissions.each end #
    else
      @actions = {"SHOW"=>true,"CREATE"=>true,"DELETE"=>true,"UPDATE"=>true}
    end # if !@current_user.is_admin end #
  end

  def new
    authorization_result = @current_user.is_authorized?(@@category, "CREATE")
    return if !process_authorization_result(authorization_result)

    @parcel = Parcel.new
    @url = admin_warehouse_parcels_path(params[:id])
    @method = :post
  end

  def create
    authorization_result = @current_user.is_authorized?(@@category, "CREATE")
    return if !process_authorization_result(authorization_result)

    @warehouse = Warehouse.find_by!(hash_id: params[:id])

    @parcel = Parcel.new(parcel_params)
    @parcel.warehouse_id = @warehouse.id
    if @parcel.save
      flash[:success] = "Paquetería creada..."
      redirect_to admin_warehouse_parcels_path(@warehouse.hash_id)
    else
      @url = admin_warehouse_parcels_path(params[:id])
      @method = :post
      flash.now[:danger] = "Ocurrió un error al guardar la paquetería"
      render :new_parcel
    end
  end

  def edit
    authorization_result = @current_user.is_authorized?(@@category, "UPDATE")
    return if !process_authorization_result(authorization_result)

    @parcel = Parcel.find(params[:id])
    @url = admin_warehouse_parcel_path(params[:warehouse_id], params[:id])
    @method = :put
  end

  def update
    authorization_result = @current_user.is_authorized?(@@category, "UPDATE")
    return if !process_authorization_result(authorization_result)

    @warehouse = Warehouse.find_by!(hash_id: params[:warehouse_id])
    @parcel = Parcel.find(params[:id])

    if @parcel.update_attributes(parcel_params)
      flash[:success] = "Paquetería actualizada..."
      redirect_to admin_warehouse_parcels_path(@warehouse.hash_id)
    else
      @url = admin_warehouse_parcel_path(params[:warehouse_id], params[:id])
      @method = :put
      flash.now[:danger] = "Ocurrió un error al guardar la paquetería"
      render :new_parcel
    end
  end

  def destroy
    authorization_result = @current_user.is_authorized?(@@category, "DELETE")
    return if !process_authorization_result(authorization_result)

    @parcel = Parcel.find(params[:id])
    if @parcel.destroy
      flash[:success] = "Paquetería eliminada..."
    else
      flash[:danger] = "Ocurrió un error inesperado..."
    end

    redirect_to admin_warehouse_parcels_path(params[:warehouse_id])
  end

  private
    def parcel_params
      params.require(:parcel).permit(:parcel_name, :cost, :image, :tracking_url)
    end

end
