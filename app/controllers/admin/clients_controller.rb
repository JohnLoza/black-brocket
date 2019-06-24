class Admin::ClientsController < AdminController

  def index
    deny_access! and return unless @current_user.has_permission_category?("clients")

    if params[:distributor]
      distributor = Distributor.find_by!(hash_id: params[:distributor])
      region_ids = distributor.Regions.map(&:id)

      if region_ids.empty?
        flash[:info] = "El distribuidor \"#{distributor.username}\" no tiene zonas asignadas."
        redirect_to admin_distributors_path and return
      end
    end

    @clients = Client.active.recent.byRegion(region_ids)
      .search(key_words: search_params, joins: {City: :State}, fields: fields_to_search)
      .paginate(page: params[:page], per_page: 20).includes(City: :State)
  end

  def show
    deny_access! and return unless @current_user.has_permission_category?("clients")

    @client = Client.find_by!(hash_id: params[:id])
    @fiscal_data = @client.FiscalData
  end

  def orders
    deny_access! and return unless @current_user.has_permission_category?("clients")

    @client = Client.find_by!(hash_id: params[:id])

    @client_city = @client.City
    @orders = @client.Orders.order(updated_at: :desc).paginate(page: params[:page], per_page: 15)
  end

  def revisions
    deny_access! and return unless @current_user.has_permission_category?("clients")

    @client = Client.find_by!(hash_id: params[:id])

    @client_city = @client.City
    @revisions = @client.DistributorRevisions.order(created_at: :desc)
      .paginate(page: params[:page], per_page: 15)
  end

  def visits
    deny_access! and return unless @current_user.has_permission_category?("clients")

    @client = Client.find_by!(hash_id: params[:id])

    @client_city = @client.City
    @visits = @client.DistributorVisits.where("client_recognizes_visit is not null")
      .order(created_at: :desc).paginate(page: params[:page], per_page: 15)
  end

  def prices
    deny_access! and return unless @current_user.has_permission_category?("clients")

    @client = Client.find_by!(hash_id: params[:id])

    @client_city = @client.City
    @products = Product.where(deleted_at: nil).order(name: :asc).paginate(page: params[:page], per_page: 15)
    @prices = @client.ProductPrices

  end

  def supervisor_visits
    deny_access! and return unless @current_user.has_permission?("clients@supervisor_visit")

    @client = Client.find_by!(hash_id: params[:id])

    @client_city = @client.City

    @visits = @client.SupervisorVisits.order(created_at: :desc)
      .paginate(page: params[:page], per_page: 25).includes(:Supervisor)
  end

  def supervisor_visit_details
    deny_access! and return unless @current_user.has_permission?("clients@supervisor_visit")

    @detail = SupervisorVisitDetail.find_by!(visit_id: params[:visit_id])
  end

  def new_supervisor_visit
    deny_access! and return unless @current_user.has_permission?("clients@supervisor_visit")

    @visit_detail = SupervisorVisitDetail.new
  end

  def create_supervisor_visit
    deny_access! and return unless @current_user.has_permission?("clients@supervisor_visit")

    client = Client.find_by!(hash_id: params[:id])

    visit = SupervisorVisit.new(worker_id: @current_user.id, client_id: client.id)
    @visit_detail = SupervisorVisitDetail.new(visit_params)

    ActiveRecord::Base.transaction do
      visit.save
      @visit_detail.visit_id = visit.id
      @visit_detail.save
      flash[:success] = "Se guardaron los datos de la encuesta."
    end

    unless flash[:success].present?
      flash[:info] = "Ocurrió un error al guardar la encuesta"
      render :new_supervisor_visit and return
    end
    redirect_to admin_clients_path
  end

  private
    def fields_to_search
      return ["cities.name","states.name","clients.name",
        "clients.email", "clients.hash_id"]
    end

    def visit_params
      params.require(:supervisor_visit_detail).permit(:client_type, :location, :local_size,
        :instalations, :infrastructure, :visibility, :motor_traffic, :walker_traffic,
        :global_profile, :years_commerce, :consumers, :client_clients_opinion_our_product,
        :client_clients_opinion_his_products, :client_clients_opinion_his_service,
        :client_workers, :client_branches, :global_commerce, :product_quality, :product_assortment,
        :product_price, :product_taste, :product_packing, :packing_aspect, :product_expiration,
        :product_shipping_packing, :need_new_products, :visits, :worker_uniform, :distributor,
        :worker, :shipment, :shipment_time, :global_service, :web_easy, :purchase_system,
        :payment_system, :purchase_follow_up, :global_web, :extra_comments,
      )
    end
end
