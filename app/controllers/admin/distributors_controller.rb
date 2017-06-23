class Admin::DistributorsController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_worker?
  layout "admin_layout.html.erb"

  @@category = "DISTRIBUTORS"

  def index
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @states = State.all.order(name: :ASC)
    @cities = Array.new

    if !params[:state_id].blank?
      @state_id = params[:state_id]
      @cities = City.where(state_id: params[:state_id])

      if !params[:city_id].blank?
        flash[:info] = "Buscando por población en zonas de distribución."
        @city_id = params[:city_id]
        city = City.find_by(id: @city_id)
        @distributors = Distributor.where(id: city.distributor_id)
            .paginate(:page =>  params[:page], :per_page => 10).includes(City: :State)
      else
        flash[:info] = "Buscando por estado en zonas de distribución."
        cities = City.where(state_id: @state_id)

        @distributors = Distributor.where(id: cities.map(&:distributor_id).uniq)
            .paginate(:page =>  params[:page], :per_page => 10).includes(City: :State)
      end
    elsif !search_params.blank?
      @distributors = Distributor.search(search_params, params[:page])
    else
      @distributors = Distributor.show_admin(params[:page])
    end

    # determine the actions the user can do, so we can display them in screen #
    @actions = {"REQUESTS"=>false,"SHOW"=>false,"CREATE"=>false,"DELETE"=>false,"UPDATE"=>false,"UPDATE_DISTRIBUTION_REGIONS"=>false}
    if !@current_user.is_admin
      @user_permissions.each do |p|
        # see if the permission category is equal to the one we need in these controller #
        if p.category == @@category
          case p.name
          when "SHOW_PERSONAL_DATA", "SHOW_FISCAL_DATA", "SHOW_BANK_DATA", "SHOW_DISTRIBUTION_REGIONS"
            @actions["SHOW"]=true
          when "CREATE"
            @actions[p.name]=true
          when "DELETE"
            @actions[p.name]=true
          when "UPDATE_PERSONAL_DATA", "UPDATE_FISCAL_DATA", "UPDATE_BANK_DATA", "UPDATE_SHOW_ADDRESS", "UPDATE_PHOTO"
            @actions["UPDATE"]=true
          when "UPDATE_DISTRIBUTION_REGIONS"
            @actions[p.name]=true
          when "REQUESTS"
            @actions[p.name]=true
          end # case p.name end #
        end # if p.category == @@category #
      end # @user_permissions.each end #
    else
      @actions = {"REQUESTS"=>true,"SHOW"=>true,"CREATE"=>true,"DELETE"=>true,"UPDATE"=>true,"UPDATE_DISTRIBUTION_REGIONS"=>true}
    end # if !@current_user.is_admin end #
  end # def index end #

  def new
    authorization_result = @current_user.is_authorized?(@@category, "CREATE")
    return if !process_authorization_result(authorization_result)

    _new()

    @distributor = Distributor.new
    @cities = Array.new
  end

  def create
    authorization_result = @current_user.is_authorized?(@@category, "CREATE")
    return if !process_authorization_result(authorization_result)

    @distributor = Distributor.new(distributor_params)
    @distributor.city_id = params[:city_id]

    @distributor.name.strip!

    if @distributor.save
      @distributor.update_attribute(:alph_key, generateAlphKey("D", @distributor.id))
      redirect_to controller: "admin/distributors"
    else
      _new()
      @city_id = params[:city_id]
      @state_id = params[:state_id]
      @cities = City.where(state_id: @state_id)

      flash.now[:danger] = 'Ocurrió un error al guardar los datos, inténtalo de nuevo por favor.'
      render :new
    end
  end

  def show
    authorization_result = @current_user.is_authorized?(@@category,
      ["SHOW_PERSONAL_DATA", "SHOW_FISCAL_DATA",
      "SHOW_BANK_DATA", "SHOW_DISTRIBUTION_REGIONS", "SHOW_COMMISSION"])
    return if !process_authorization_result(authorization_result)

    @distributor = Distributor.find_by(alph_key: params[:id])
    if @distributor.nil?
      flash[:info] = "No se encontró el distribuidor con clave: #{params[:id]}"
      redirect_to admin_distributors_path
      return
    end

    @distributor_city = @distributor.City
    @regions = @distributor.Regions

    # determine what the user can see #
    @actions = {"SHOW_PERSONAL_DATA"=>false, "SHOW_FISCAL_DATA"=>false, "SHOW_BANK_DATA"=>false, "SHOW_DISTRIBUTION_REGIONS"=>false, "SHOW_COMMISSION"=>false}
    if !@current_user.is_admin
      @user_permissions.each do |p|
        # see if the permission category is equal to the one we need in these controller #
        if p.category == @@category
          if ["SHOW_PERSONAL_DATA", "SHOW_FISCAL_DATA",
              "SHOW_BANK_DATA", "SHOW_DISTRIBUTION_REGIONS", "SHOW_COMMISSION"].include? p.name
            @actions[p.name]=true
          end # case p.name end #
        end # if p.category == @@category #
      end # @user_permissions.each end #
    else
      @actions = {"SHOW_PERSONAL_DATA"=>true, "SHOW_FISCAL_DATA"=>true, "SHOW_BANK_DATA"=>true, "SHOW_DISTRIBUTION_REGIONS"=>true, "SHOW_COMMISSION"=>true}
    end # if !@current_user.is_admin end #
  end

  def edit
    authorization_result = @current_user.is_authorized?(@@category, ["UPDATE_PERSONAL_DATA", "UPDATE_FISCAL_DATA",
      "UPDATE_BANK_DATA", "UPDATE_SHOW_ADDRESS", "UPDATE_PHOTO", "UPDATE_COMMISSION"])
    return if !process_authorization_result(authorization_result)

    _edit()

    @distributor = Distributor.find_by(alph_key: params[:id])
    if @distributor.nil?
      flash[:info] = "No se encontró el distribuidor con clave: #{params[:id]}"
      redirect_to admin_distributors_path
      return
    end

    distributor_city = @distributor.City
    @city_id = distributor_city.id
    @state_id = distributor_city.State.id
    @cities = City.where(state_id: @state_id)
  end

  def update
    authorization_result = @current_user.is_authorized?(@@category, ["UPDATE_PERSONAL_DATA", "UPDATE_FISCAL_DATA",
      "UPDATE_BANK_DATA", "UPDATE_SHOW_ADDRESS", "UPDATE_PHOTO"])
    return if !process_authorization_result(authorization_result)

    @distributor = Distributor.find_by(alph_key: params[:id])
    if @distributor.nil?
      flash[:info] = "No se encontró el distribuidor con clave: #{params[:id]}"
      redirect_to admin_distributors_path
      return
    end

    @distributor.city_id = params[:city_id]

    if @distributor.update_attributes(distributor_params)
      flash[:success] = "El distribuidor se actualizó."
      redirect_to admin_distributors_path
    else
      _edit()
      @city_id = params[:city_id]
      @state_id = params[:state_id]
      @cities = City.where(state_id: @state_id)

      flash.now[:danger] = 'Ocurrió un error al guardar los datos, inténtalo de nuevo por favor.'
      render :edit
    end
  end

  def destroy
    authorization_result = @current_user.is_authorized?(@@category, "DELETE")
    return if !process_authorization_result(authorization_result)

    @distributor = Distributor.find_by(alph_key: params[:id])
    if @distributor.nil?
      flash[:info] = "No se encontró el distribuidor con clave: #{params[:id]}"
      redirect_to admin_distributors_path
      return
    end

    if @distributor.update_attributes(:deleted => true)
      cities = @distributor.Regions
      cities.update_all(distributor_id: nil)
      redirect_to controller: "admin/distributors"
    else
      flash[:danger] = 'Ocurrió un error al eliminar el trabajador, inténtalo de nuevo por favor.'
      redirect_to controller: "admin/distributors"
    end
  end

  # @deprecated
  def clients
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @distributor = Distributor.find_by(alph_key: params[:id])
    if @distributor.nil?
      flash[:info] = "No se encontró el distribuidor con clave: #{params[:id]}"
      redirect_to admin_distributors_path
      return
    end

    if @distributor
      @distributor_city = @distributor.City
      regions = @distributor.Regions.map(&:id)
      @clients = Client.where(city_id: regions).order(name: :asc).paginate(page: params[:page], per_page: 20)
    end
  end

  def candidates
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @candidates = DistributorCandidate.all.order(created_at: :desc)
                    .paginate(page: params[:page], per_page: 20).includes(:City)
  end

  def update_candidate
    candidate = DistributorCandidate.find(params[:id])

    if candidate
      candidate.update_attribute(:read, true)
    end
  end

  private
    def distributor_params
      params.require(:distributor).permit(:name, :username, :email, :rfc, :birthday,
                        :address, :telephone, :password, :password_confirmation,
                        :fiscal_number, :lastname, :mother_lastname, :commission,
                        :photo, :cellphone, :bank_name, :bank_account_owner,
                        :bank_account_number, :interbank_clabe, :show_address)
    end

    def search_params
      params[:distributor][:search] if params[:distributor]
    end

    def _new
      @states = State.all.order(:name)
      @url = admin_distributors_path

      @actions = {"CREATE"=>false}
      if !@current_user.is_admin
        @user_permissions.each do |p|
          # see if the permission category is equal to the one we need in these controller #
          if p.category == @@category and p.name == "CREATE"
            @actions[p.name] = true
            break
          end # if p.category == @@category #
        end # @user_permissions.each end #
      else
        @actions = {"CREATE"=>true}
      end # if !@current_user.is_admin end #
    end

    def _edit
      @states = State.all.order(:name)
      @url = admin_distributor_path(params[:id])

      # determine the actions the user can do, so we can display them in screen #
      @actions = {"UPDATE_PERSONAL_DATA"=>false, "UPDATE_FISCAL_DATA"=>false,
        "UPDATE_BANK_DATA"=>false, "UPDATE_SHOW_ADDRESS"=>false, "UPDATE_PHOTO"=>false,"UPDATE_COMMISSION"=>false}
      if !@current_user.is_admin
        @user_permissions.each do |p|
          # see if the permission category is equal to the one we need in these controller #
          if p.category == @@category
            if ["UPDATE_PERSONAL_DATA", "UPDATE_FISCAL_DATA", "UPDATE_COMMISSION",
              "UPDATE_BANK_DATA", "UPDATE_SHOW_ADDRESS", "UPDATE_PHOTO"].include? p.name
              @actions[p.name]=true
            end # if p.name == "UPDATE_PERSONAL_INFORMATION" or p.name == "UPDATE_WAREHOUSE" end #
          end # if p.category == @@category #
        end # @user_permissions.each end #
      else
        @actions = {"UPDATE_PERSONAL_DATA"=>true, "UPDATE_FISCAL_DATA"=>true,
          "UPDATE_BANK_DATA"=>true, "UPDATE_SHOW_ADDRESS"=>true, "UPDATE_PHOTO"=>true,"UPDATE_COMMISSION"=>true}
      end # if !@current_user.is_admin end #

    end

end
