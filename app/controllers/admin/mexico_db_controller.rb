class Admin::MexicoDbController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_worker?
  layout "admin_layout.html.erb"

  @@category = "MEXICO_DB"

  def index
    authorization_result = current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @states = State.all.order(name: :ASC)

    # determine the actions the user can do, so we can display them in screen #
    @actions = {"CREATE"=>false,"UPDATE"=>false,"UPDATE_STATE_LADA"=>false}
    if !current_user.is_admin
      @user_permissions.each do |p|
        # see if the permission category is equal to the one we need in these controller #
        if p.category == @@category
          case p.name
          when "UPDATE_STATE_LADA"
            @actions[p.name] = true
          when "CREATE"
            @actions[p.name] = true
          when "UPDATE_CITY_NAME", "UPDATE_CITY_LADA"
            @actions["UPDATE"] = true
          end # case p.name #
        end # if p.category == @@category #
      end # @user_permissions.each end #
    else
      @actions = {"CREATE"=>true,"UPDATE"=>true,"UPDATE_STATE_LADA"=>true}
    end # if !current_user.is_admin end #
  end

  def state
    authorization_result = current_user.is_authorized?(@@category, ["CREATE", "UPDATE_CITY_NAME", "UPDATE_CITY_LADA"])
    return if !process_authorization_result(authorization_result)

    @state = State.find_by(id: params[:id])
    if @state.nil?
      flash[:info] = "No se encontró el estado con clave: #{params[:id]}"
      redirect_to admin_mexico_db_path
      return
    end

    if @state
      @cities = City.where(state_id: @state.id).order(name: :ASC)
    else
      @cities = Array.new
    end

    # determine the actions the user can do, so we can display them in screen #
    @actions = {"CREATE"=>false,"UPDATE_CITY_NAME"=>false,"UPDATE_CITY_LADA"=>false}
    if !current_user.is_admin
      @user_permissions.each do |p|
        # see if the permission category is equal to the one we need in these controller #
        if p.category == @@category
          if ["CREATE","UPDATE_CITY_LADA","UPDATE_CITY_NAME"].include? p.name
            @actions[p.name] = true
          end
        end # if p.category == @@category #
      end # @user_permissions.each end #
    else
      @actions = {"CREATE"=>true,"UPDATE_CITY_NAME"=>true,"UPDATE_CITY_LADA"=>true}
    end # if !current_user.is_admin end #
  end

  def update_state_lada
    authorization_result = current_user.is_authorized?(@@category, "UPDATE_STATE_LADA")
    return if !process_authorization_result(authorization_result)

    @state = State.find(params[:id]) if params[:id].to_i > 0
    if @state
      City.where(:state_id => @state.id).update_all(lada: params[:state][:lada])
      flash[:success] = "El LADA para el estado #{@state.name} se actualizó correctamente"
    else
      flash[:danger] = "Oops, algo no salió como esperabamos..."
    end

    redirect_to admin_mexico_db_path
  end

  def update_city
    authorization_result = current_user.is_authorized?(@@category, ["UPDATE_CITY_NAME", "UPDATE_CITY_LADA"])
    return if !process_authorization_result(authorization_result)

    @city = City.find(params[:id])

    if @city
      @city.update(city_params)
      flash[:success] = "La información de #{@city.name} se actualizó correctamente"
    else
      flash[:danger] = "Oops, algo no salió como esperabamos..."
    end

    redirect_to admin_mexico_state_path(@city.state_id)
  end

  def create_city
    authorization_result = current_user.is_authorized?(@@category, "CREATE")
    return if !process_authorization_result(authorization_result)

    city = City.create({lada: params[:new_city][:lada], name: params[:new_city][:name], state_id: params[:new_city][:state_id]})
    if city
      flash[:success] = "La ciudad " + city.name + " se creó correctamente."
    else
      flash[:danger] = "Oops, algo no salió como lo planeado.s"
    end

    redirect_to admin_mexico_state_path(params[:new_city][:state_id])
  end

  private
    def city_params
      params.require(:city).permit(:name, :lada)
    end
end
