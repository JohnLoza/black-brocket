class Admin::WarehousesController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_worker?
  layout "admin_layout.html.erb"

  @@category = "WAREHOUSES"

  def index
    authorization_result = current_user.is_authorized?(@@category, nil)
    authorization_result2 = current_user.is_authorized?("PARCELS", nil)
    authorization_result3 = current_user.is_authorized?("WAREHOUSE_PRODUCTS", nil)
    authorization_result4 = current_user.is_authorized?("WAREHOUSE_MANAGER", nil)

    if process_authorization_result(authorization_result4, false) and !current_user.is_admin
      warehouse_key = current_user.Warehouse.hash_id
      redirect_to admin_warehouse_products_path(warehouse_key)
      return
    elsif !process_authorization_result(authorization_result, false) and
          !process_authorization_result(authorization_result2, false) and
          !process_authorization_result(authorization_result3, false)
      redirect_to admin_welcome_path
      return
    end

    # Proceed if the user is the warehouse chief or system admin #
    if search_params
      @warehouses = Warehouse.search(search_params, params[:page])
    else
      @warehouses = Warehouse.find_active_ones(params[:page])
    end

    # determine the actions the user can do, so we can display them in screen #
    @actions = {"SHOW"=>false,"CREATE"=>false,"DELETE"=>false,"UPDATE"=>false,
             "UPDATE_REGIONS"=>false,"WAREHOUSE_PRODUCTS"=>false,"PARCELS"=>false,
             "BATCH_SEARCH"=>false}
    if !current_user.is_admin
      @user_permissions.each do |p|
        # see if the permission category is equal to the one we need in these controller #
        if p.category == @@category
          case p.name
          when "UPDATE_WAREHOUSE_DATA", "UPDATE_SHIPPING_COST", "UPDATE_WHOLESALE"
            @actions["UPDATE"]=true
          else
            @actions[p.name]=true
          end # case p.name end #
        else
          case p.category
          when "PARCELS"
            @actions[p.category]=true
          when "WAREHOUSE_PRODUCTS", "WAREHOUSE_MANAGER"
            if p.name == "BATCH_SEARCH"
              @actions[p.name]=true
            else
              @actions["WAREHOUSE_PRODUCTS"]=true
            end
          end # case p.category end #
        end # if p.category == @@category #
      end # @user_permissions.each end #
    else
      @actions = {"SHOW"=>true,"CREATE"=>true,"DELETE"=>true,"UPDATE"=>true,
              "UPDATE_REGIONS"=>true,"WAREHOUSE_PRODUCTS"=>true,"PARCELS"=>true,
              "BATCH_SEARCH"=>true}
    end # if !current_user.is_admin end #

  end

  def show
    authorization_result = current_user.is_authorized?(@@category, "SHOW")
    return if !process_authorization_result(authorization_result)

    @warehouse = Warehouse.find_by(hash_id: params[:id])
    if @warehouse.nil?
      flash[:info] = "No se encontró el almacén con clave: #{params[:id]}"
      redirect_to admin_warehouses_path
      return
    end

    @warehouse_city = @warehouse.City
  end

  def new
    authorization_result = current_user.is_authorized?(@@category, "CREATE")
    return if !process_authorization_result(authorization_result)

    _new()

    @warehouse = Warehouse.new
    @cities = Array.new
  end

  def create
    authorization_result = current_user.is_authorized?(@@category, "CREATE")
    return if !process_authorization_result(authorization_result)

    @warehouse = Warehouse.new(warehouse_params)
    @warehouse.city_id = params[:city_id]

    @warehouse.name.strip!

    ActiveRecord::Base.transaction do
      if @warehouse.save
        @warehouse.update_attribute(:hash_id, generateAlphKey("A", @warehouse.id))

        Product.all.each do |p|
          WarehouseProduct.create(warehouse_id: @warehouse.id,
                  describes_total_stock: true, product_id: p.id, existence: 0,
                  min_stock: 50, hash_id: random_hash_id(12).upcase)
        end

        redirect_to admin_warehouses_path
        return
      else
        _new()
        @city_id = params[:city_id]
        @state_id = params[:state_id]

        @cities = City.where(state_id: @state_id)
        flash.now[:danger] = 'Ocurrió un error al guardar los datos, inténtalo de nuevo por favor.'
        render :new
      end # if @warehouse.save #
    end # Transaction #
  end

  def edit
    authorization_result = current_user.is_authorized?(@@category, ["UPDATE_WAREHOUSE_DATA","UPDATE_WHOLESALE","UPDATE_SHIPPING_COST"])
    return if !process_authorization_result(authorization_result)

    _edit()
    @warehouse = Warehouse.find_by(hash_id: params[:id])
    warehouse_city = @warehouse.City
    @city_id = warehouse_city.id
    @state_id = warehouse_city.State.id

    @cities = City.where(state_id: @state_id)
  end

  def update
    authorization_result = current_user.is_authorized?(@@category, ["UPDATE_WAREHOUSE_DATA","UPDATE_WHOLESALE","UPDATE_SHIPPING_COST"])
    return if !process_authorization_result(authorization_result)

    @warehouse = Warehouse.find_by(hash_id: params[:id])
    @warehouse.city_id = params[:city_id]

    if @warehouse.update_attributes(warehouse_params)
      redirect_to admin_warehouses_path
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
    @warehouse = Warehouse.find_by(hash_id: params[:id])
    if @warehouse.update_attributes(:deleted => true)
      @warehouse.Regions.update_all(warehouse_id: nil)
      redirect_to controller: "admin/warehouses"
    else
      flash[:danger] = 'Ocurrió un error al eliminar el trabajador, inténtalo de nuevo por favor.'
      redirect_to controller: "admin/warehouses"
    end
  end

  def batch_search
    authorization_result = current_user.is_authorized?("WAREHOUSE_PRODUCTS", "BATCH_SEARCH")
    return if !process_authorization_result(authorization_result)

    if params[:batch]
      @products_in_warehouse = WarehouseProduct.where(batch: params[:batch]).includes(:Warehouse)

      @products_to_ship = OrderProductShipmentDetail.joins(:Order)
                          .where(orders: {state: ["BATCHES_CAPTURED", "INSPECTIONED"]})
                          .where(batch: params[:batch]).includes(Order: :Client)

      @products_shipped = OrderProductShipmentDetail.joins(:Order)
                          .where(orders: {state: ["SENT", "DELIVERED"]})
                          .where(batch: params[:batch]).includes(Order: :Client)
    end
  end

  def inventory
    authorization_result = current_user.is_authorized?("WAREHOUSE_PRODUCTS", "INVENTORY")
    return if !process_authorization_result(authorization_result)

    @warehouse = Warehouse.find_by(hash_id: params[:warehouse_id])
    if @warehouse.nil?
      flash[:warning] = "No se encontró el almacén especificado."
      redirect_to admin_warehouses_path
      return
    end

    @products_in_stock = @warehouse.Products.joins(:Product).where(products: {deleted: false})
                          .where(warehouse_id: @warehouse.id, describes_total_stock: true)
                          .order(product_id: :asc).includes(:Product)

    @products_no_pay = OrderDetail.select("product_id, sum(quantity) as sum_quantity").joins(:Order)
                                        .where(orders: {state: ["WAITING_FOR_PAYMENT", "PAYMENT_DEPOSITED", "PAYMENT_REJECTED"],
                                        warehouse_id: @warehouse.id}).group(:product_id)

    @products_paid = OrderDetail.select("product_id, sum(quantity) as sum_quantity").joins(:Order)
                                        .where(orders: {state: ["PAYMENT_ACCEPTED", "BATCHES_CAPTURED"],
                                        warehouse_id: @warehouse.id}).group(:product_id)

    @complement = OrderDetail.joins(:Order)
                            .where(orders: {state: ["INSPECTIONED"],
                            warehouse_id: @warehouse.id}).includes(:Order)


    render :inventory, layout: false
  end

  private
    def warehouse_params
      params.require(:warehouse).permit(:name, :address, :telephone, :shipping_cost, :wholesale)
    end

    def search_params
      params[:warehouse][:search] if params[:warehouse]
    end

    def _new
      @states = State.all.order(:name)
      @url = admin_warehouses_path

      @actions = {"CREATE"=>false}
      if !current_user.is_admin
        @user_permissions.each do |p|
          # see if the permission category is equal to the one we need in these controller #
          if p.category == @@category and p.name == "CREATE"
            @actions[p.name] = true
            break
          end # p.category == @@category and p.name == "CREATE" #
        end # @user_permissions.each end #
      else
        @actions = {"CREATE"=>true}
      end # if !current_user.is_admin end #
    end

    def _edit
      @states = State.all.order(:name)
      @url = admin_warehouse_path(params[:id])

      # determine the actions the user can do, so we can display them in screen #
      @actions = {"UPDATE_WAREHOUSE_DATA"=>false,"UPDATE_WHOLESALE"=>false,"UPDATE_SHIPPING_COST"=>false}
      if !current_user.is_admin
        @user_permissions.each do |p|
          # see if the permission category is equal to the one we need in these controller #
          if p.category == @@category
            if ["UPDATE_WAREHOUSE_DATA","UPDATE_WHOLESALE","UPDATE_SHIPPING_COST"].include? p.name
              @actions[p.name]=true
            end # if p.name == "UPDATE_PERSONAL_INFORMATION" or p.name == "UPDATE_WAREHOUSE" end #
          end # if p.category == @@category #
        end # @user_permissions.each end #
      else
        @actions = {"UPDATE_WAREHOUSE_DATA"=>true,"UPDATE_WHOLESALE"=>true,"UPDATE_SHIPPING_COST"=>true}
      end # if !current_user.is_admin end #
    end
end
