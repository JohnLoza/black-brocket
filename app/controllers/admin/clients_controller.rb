class Admin::ClientsController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_worker?
  layout "admin_layout.html.erb"

  @@category = "CLIENTS"

  def index
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    if search_params

      page = params[:page]
      @clients = Client.search(search_params, page)

    elsif params[:distributor]

      @distributor = Distributor.find_by(alph_key: params[:distributor])
      if @distributor.nil?
        flash[:info] = "No se encontró el distribuidor con clave: #{params[:distributor]}"
        redirect_to admin_distributors_path
        return
      end # if !@distributor.nil? #

      @distributor_city = @distributor.City
      region_ids = @distributor.Regions.map(&:id)
      @clients = Client.where(city_id: region_ids).order(name: :asc).paginate(page: params[:page], per_page: 20)

    else
      @clients = Client.all.order(created_at: :desc).paginate(page: params[:page], per_page: 20).includes(City: :State)
    end # if search_params #

    # determine the actions the user can do, so we can display them in screen #
    @actions = {"SUPERVISOR_VISIT"=>false}
    if !@current_user.is_admin
      @user_permissions.each do |p|
        # see if the permission category is equal to the one we need in these controller #
        if p.category == @@category
          @actions[p.name] = true
        end # if p.category == @@category #
      end # @user_permissions.each end #
    else
      @actions = {"SUPERVISOR_VISIT"=>true}
    end # if !@current_user.is_admin end #
  end

  def show
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @client = Client.find_by(alph_key: params[:id])
    @client_city = @client.City
    @fiscal_data = @client.FiscalData
  end

  def orders
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @client = Client.find_by(alph_key: params[:id])
    if @client.nil?
      flash[:info] = "No se encontró el cliente con clave: #{params[:id]}"
      redirect_to admin_clients_path
      return
    end

    @client_city = @client.City
    @orders = @client.Orders.order(updated_at: :desc).paginate(page: params[:page], per_page: 15)

  end

  def revisions
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @client = Client.find_by(alph_key: params[:id])
    if @client.nil?
      flash[:info] = "No se encontró el cliente con clave: #{params[:id]}"
      redirect_to admin_clients_path
      return
    end

    @client_city = @client.City
    @revisions = @client.DistributorRevisions.order(created_at: :desc).paginate(page: params[:page], per_page: 15)

  end

  def visits
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @client = Client.find_by(alph_key: params[:id])
    if @client.nil?
      flash[:info] = "No se encontró el cliente con clave: #{params[:id]}"
      redirect_to admin_clients_path
      return
    end

    @client_city = @client.City
    @visits = @client.DistributorVisits.where("client_recognizes_visit is not null").order(created_at: :desc).paginate(page: params[:page], per_page: 15)

  end

  def prices
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @client = Client.find_by(alph_key: params[:id])
    if @client.nil?
      flash[:info] = "No se encontró el cliente con clave: #{params[:id]}"
      redirect_to admin_clients_path
      return
    end

    @client_city = @client.City
    @products = Product.where(deleted: false).order(name: :asc).paginate(page: params[:page], per_page: 15)
    @prices = @client.ProductPrices

  end

  def supervisor_visits
    authorization_result = @current_user.is_authorized?(@@category, "SUPERVISOR_VISIT")
    return if !process_authorization_result(authorization_result)

    @client = Client.find_by(alph_key: params[:id])
    if @client.nil?
      flash[:info] = "No se encontró el cliente con clave: #{params[:id]}"
      redirect_to admin_clients_path
      return
    end

    @client_city = @client.City

    @visits = @client.SupervisorVisits.order(:created_at => :desc).paginate(page: params[:page], per_page: 25).includes(:Supervisor)
  end

  def supervisor_visit_details
    authorization_result = @current_user.is_authorized?(@@category, "SUPERVISOR_VISIT")
    return if !process_authorization_result(authorization_result)

    @detail = SupervisorVisitDetail.where(visit_id: params[:visit_id]).take
    if @detail.nil?
      flash[:warning] = "No se encontraron los detalles"
      redirect_to admin_supervisor_visits_path(params[:id])
      return
    end
  end

  def new_supervisor_visit
    authorization_result = @current_user.is_authorized?(@@category, "SUPERVISOR_VISIT")
    return if !process_authorization_result(authorization_result)

    @visit_detail = SupervisorVisitDetail.new
  end

  def create_supervisor_visit
    authorization_result = @current_user.is_authorized?(@@category, "SUPERVISOR_VISIT")
    return if !process_authorization_result(authorization_result)

    client = Client.find_by(alph_key: params[:id])
    if client.nil?
      flash[:info] = "No se encontró el cliente con clave: #{params[:id]}"
      redirect_to admin_clients_path
      return
    end

    visit = SupervisorVisit.new(worker_id: @current_user.id, client_id: client.id)
    @visit_detail = SupervisorVisitDetail.new(visit_params)

    saved = false
    ActiveRecord::Base.transaction do
      visit.save
      @visit_detail.visit_id = visit.id
      @visit_detail.save
      saved = true
    end

    if !saved
      flash[:danger] = "Ocurrió un error al guardar la encuesta"
      render :new_supervisor_visit
      return
    end
    flash[:success] = "Se guardaron los datos de la encuesta." if saved
    redirect_to admin_clients_path
  end

  private
    def search_params
      params[:client][:search] if params[:client]
    end

    def visit_params
      params.require(:supervisor_visit_detail).permit(
      :client_type,
      :location,
      :local_size,
      :instalations,
      :infrastructure,
      :visibility,
      :motor_traffic,
      :walker_traffic,
      :global_profile,
      :years_commerce,
      :consumers,
      :client_clients_opinion_our_product,
      :client_clients_opinion_his_products,
      :client_clients_opinion_his_service,
      :client_workers,
      :client_branches,
      :global_commerce,
      :product_quality,
      :product_assortment,
      :product_price,
      :product_taste,
      :product_packing,
      :packing_aspect,
      :product_expiration,
      :product_shipping_packing,
      :need_new_products,
      :visits,
      :worker_uniform,
      :distributor,
      :worker,
      :shipment,
      :shipment_time,
      :global_service,
      :web_easy,
      :purchase_system,
      :payment_system,
      :purchase_follow_up,
      :global_web,
      :extra_comments,
      )
    end
end
