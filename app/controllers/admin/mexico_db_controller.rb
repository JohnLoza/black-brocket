class Admin::MexicoDbController < AdminController

  def index
    deny_access! and return unless @current_user.has_permission_category?("mexico_db")

    @states = State.order_by_name
  end

  def state
    unless @current_user.has_permission?("mexico_db@create") or
      @current_user.has_permission?("mexico_db@update_city_name") or
      @current_user.has_permission?("mexico_db@update_city_lada")
      deny_access! and return
    end

    @state = State.find_by!(id: params[:id])
    @cities = @state.Cities.order_by_name
  end

  def update_state_lada
    deny_access! and return unless @current_user.has_permission?("mexico_db@update_state_lada")

    @state = State.find_by!(id: params[:id])
    @state.Cities.update_all(lada: params[:state][:lada])
    flash[:success] = "El LADA para el estado #{@state.name} se actualizó correctamente"

    redirect_to admin_mexico_db_path
  end

  def update_city
    unless @current_user.has_permission?("mexico_db@update_city_name") or
      @current_user.has_permission?("mexico_db@update_city_lada")
      deny_access! and return
    end

    @city = City.find_by!(id: params[:id])

    @city.update(city_params)
    flash[:success] = "La información de #{@city.name} se actualizó correctamente"

    redirect_to admin_mexico_state_path(@city.state_id)
  end

  def create_city
    deny_access! and return unless @current_user.has_permission?("mexico_db@create")

    city = City.new(new_city_params)
    if city.save
      flash[:success] = "La población " + city.name + " se creó correctamente."
    else
      flash[:info] = "Oops, algo no salió como lo planeado.s"
    end

    redirect_to admin_mexico_state_path(params[:new_city][:state_id])
  end

  private
    def city_params
      params.require(:city).permit(:name, :lada)
    end

    def new_city_params
      params.require(:new_city).permit(:lada, :name, :state_id)
    end
end
