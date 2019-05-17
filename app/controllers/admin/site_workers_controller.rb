class Admin::SiteWorkersController < AdminController

  def index
    deny_access! and return unless @current_user.has_permission_category?('site_workers')

    @workers =
      SiteWorker.non_admin.not(@current_user.id).active.order_by_name
        .search(key_words: search_params, joins: {City: :State}, fields: fields_to_search)
        .paginate(page: params[:page], per_page: 20).includes(City: :State)
  end # def index end #

  def new
    deny_access! unless @current_user.has_permission?('site_workers@create')

    @worker = SiteWorker.new
    @states = State.order_by_name
    @cities = Array.new
    @warehouses = Warehouse.active
  end # def new end #

  def create
    deny_access! unless @current_user.has_permission?('site_workers@create')

    @worker = SiteWorker.new(worker_params)
    @worker.city_id = params[:city_id]

    if @worker.save
      @worker.update_attribute(:hash_id, generateAlphKey("T", @worker.id))
      redirect_to admin_site_workers_path
    else
      @cities = City.where(state_id: params[:state_id]).order_by_name
      @states = State.order_by_name
      @warehouse_id = params[:site_worker][:warehouse_id]
      @warehouses = Warehouse.active

      flash.now[:danger] = 'Ocurrió un error al guardar los datos, inténtalo de nuevo por favor.'
      render :new
    end
  end # def create end #

  def show
    deny_access! and return unless @current_user.has_permission?('site_workers@show')

    @worker = SiteWorker.includes(City: :State).find_by!(hash_id: params[:id])
    deny_access! and return unless current_user_is_admin_or_same_warehouse?(@worker)
  end # def show end #

  def edit
    deny_access! and return unless @current_user.has_permission?('site_workers@update_personal_data') or
      @current_user.has_permission?('site_workers@update_warehouse')

    @worker = SiteWorker.find_by!(hash_id: params[:id])
    deny_access! and return unless current_user_is_admin_or_same_warehouse?(@worker)

    @warehouse_id = @worker.warehouse_id
    @warehouses = Warehouse.active.order_by_name
    params[:city_id] = @worker.city_id
    params[:state_id] = @worker.City.state_id
    @cities = City.where(state_id: params[:state_id]).order_by_name
    @states = State.order_by_name
  end # def edit end #

  def update
    deny_access! and return unless @current_user.has_permission?('site_workers@update_personal_data') or
      @current_user.has_permission?('site_workers@update_warehouse')

    @worker = SiteWorker.find_by!(hash_id: params[:id])
    deny_access! and return unless current_user_is_admin_or_same_warehouse?(@worker)

    @worker.city_id = params[:city_id]

    if @worker.update_attributes(worker_params)
      redirect_to admin_site_workers_path, flash: {success: 'Trabajador actualizado correctamente.' }
    else
      @warehouse_id = params[:site_worker][:warehouse_id]
      @warehouses = Warehouse.active.order_by_name
      @cities = City.where(state_id: params[:state_id]).order_by_name
      @states = State.order_by_name

      flash.now[:danger] = 'Ocurrió un error al guardar los datos, inténtalo de nuevo por favor.'
      render :edit
    end
  end # def update end #

  def destroy
    deny_access! and return unless @current_user.has_permission?('site_workers@delete')

    @worker = SiteWorker.find_by!(hash_id: params[:id])
    deny_access! and return unless current_user_is_admin_or_same_warehouse?(@worker)

    if @worker.destroy
      redirect_to admin_site_workers_path, flash: {success: 'Trabajador eliminado.' }
    else
      redirect_to admin_site_workers_path, flash: { warning: 'Ocurrió un error al eliminar el trabajador.' }
    end
  end # def destroy end #

  def edit_permissions
    deny_access! and return unless @current_user.has_permission?('site_workers@update_permissions')

    @worker = SiteWorker.find_by!(hash_id: params[:id])
    deny_access! and return unless current_user_is_admin_or_same_warehouse?(@worker)

    @user_permissions = @worker.Permissions

    build_up_permission_arrays
  end # def edit_permissions end #

  def update_permissions
    deny_access! and return unless @current_user.has_permission?('site_workers@update_permissions')

    @worker = SiteWorker.find_by!(hash_id: params[:id])
    deny_access! and return unless current_user_is_admin_or_same_warehouse?(@worker)

    ActiveRecord::Base.transaction do
      @worker.Permissions.destroy_all
      params[:permission].keys.each do |key|
        next unless params[:permission][key] == "1"
        category = key.split("-")[0].upcase
        permission_name = key.split("-")[1].upcase
        @worker.Permissions << Permission.new(category: category, name: permission_name)
      end
    end

    if @worker.save
      flash[:success] = "Permisos guardados"
    else
      flash[:info] = "Ocurrió un error inesperado"
    end
    redirect_to admin_site_workers_path
  end # def update_permissions end #

  private
    def worker_params
      params.require(:site_worker).permit(:name, :username, :email, :rfc,
                        :nss, :address, :telephone, :password,
                        :password_confirmation, :warehouse_id, :birthday,
                        :lastname, :mother_lastname, :photo, :cellphone,
                        :email_confirmation)
    end

    def permission_params
      params.require(:permission).permit(:workers, :distributors, :products,
                            :warehouses, :warehouse_chief, :products_questions,
                            :statistics, :authorize_payments, :send_orders,
                            :invoices, :verify_delivery, :web)
    end

    def fields_to_search
      return ['cities.name','states.name','site_workers.name',
        'site_workers.lastname','site_workers.mother_lastname',
        'site_workers.hash_id']
    end

    def current_user_is_admin_or_same_warehouse?(worker)
      if !@current_user.is_admin
        # non admin users cant see admin data
        return false if worker.is_admin
        # non admin users cant see user's data from another warehouse
        return false if worker.warehouse_id != @current_user.warehouse_id
      end
      return true
    end

    def build_up_permission_arrays
      # These are the current permissions available in the system#
      @worker_category = []
      @worker_category << {category: "site_workers", name: "show", description: "Ver información de los trabajadores"}
      @worker_category << {category: "site_workers", name: "create", description: "Dar de alta trabajador"}
      @worker_category << {category: "site_workers", name: "delete", description: "Eliminar (dar de baja un trabajador)"}
      @worker_category << {category: "site_workers", name: "update_personal_data", description: "Modificar información personal"}
      @worker_category << {category: "site_workers", name: "update_warehouse", description: "Modificar almacén al que está asignado"}
      @worker_category << {category: "site_workers", name: "update_permissions", description: "Modificar permisos"}

      @distributor_category = []
      @distributor_category << {category: "distributor_work", name: "all", description: "Fungir como distribuidor"}
      @distributor_category << {category: "distributors", name: "requests", description: "Atender solicitudes de distribuidor"}
      @distributor_category << {category: "distributors", name: "show_personal_data", description: "Ver información personal"}
      @distributor_category << {category: "distributors", name: "show_fiscal_data", description: "Ver información fiscal"}
      @distributor_category << {category: "distributors", name: "show_bank_data", description: "Ver datos bancarios"}
      @distributor_category << {category: "distributors", name: "show_commission", description: "Ver porcentaje de comisión"}
      @distributor_category << {category: "distributors", name: "show_distribution_regions", description: "Ver zonas de distribución"}
      @distributor_category << {category: "distributors", name: "create", description: "Dar de alta distribuidor"}
      @distributor_category << {category: "distributors", name: "delete", description: "Eliminar (dar de baja un distribuidor)"}
      @distributor_category << {category: "distributors", name: "update_personal_data", description: "Modificar información personal"}
      @distributor_category << {category: "distributors", name: "update_fiscal_data", description: "Modificar información fiscal"}
      @distributor_category << {category: "distributors", name: "update_bank_data", description: "Modificar información bancaria"}
      @distributor_category << {category: "distributors", name: "update_distribution_regions", description: "Modificar zonas de distribución"}
      @distributor_category << {category: "distributors", name: "update_show_address", description: "Modificar estatus de vista del domicilio al público"}
      @distributor_category << {category: "distributors", name: "update_commission", description: "Modificar su porcentaje de comisión"}
      @distributor_category << {category: "distributors", name: "update_photo", description: "Modificar fotografía"}

      @supervisor_category = []
      @supervisor_category << {category: "clients", name: "supervisor_visit", description: "Visitas de supervisor al cliente"}
      @supervisor_category << {category: "warehouse_products", name: "inventory", description: "Impresión de inventario"}
      @supervisor_category << {category: "distributors", name: "show_personal_data", description: "Ver distribuidores"}
      @supervisor_category << {category: "clients", name: "show", description: "Ver clientes"}
      @supervisor_category << {category: "orders", name: "show", description: "Ver órdenes"}

      @commission_category = []
      @commission_category << {category: "commissions", name: "show", description: "Ver comisiones"}
      @commission_category << {category: "commissions", name: "create", description: "Dar de alta comisiones"}
      @commission_category << {category: "commissions", name: "pay", description: "Subir comprobante de pago de comisiones"}
      @commission_category << {category: "commissions", name: "invoices", description: "Ver comisiones facturadas"}

      @product_category = []
      @product_category << {category: "products", name: "show", description: "Ver información e imágenes de productos"}
      @product_category << {category: "products", name: "create", description: "Dar de alta producto"}
      @product_category << {category: "products", name: "delete", description: "Eliminar (dar de baja un producto)"}
      @product_category << {category: "products", name: "update_name", description: "Modificar nombre del producto"}
      @product_category << {category: "products", name: "update_product_data", description: "Modificar datos del producto (Descripción, Preparación del producto, Presentación, Categorías, cargar video, cargar fotografía de portada y secundarias)"}
      @product_category << {category: "products", name: "update_price", description: "Modificar precios"}
      @product_category << {category: "products", name: "update_show_in_web_page", description: "Modificar estado de visualización en la página web"}

      @warehouse_manager_category = []
      @warehouse_manager_category << {category: "warehouse_manager", name: "receive_shipments", description: "Recibir mercancías"}
      @warehouse_manager_category << {category: "warehouse_manager", name: "transfer_mercancy", description: "Traspasar mercancías"}

      @warehouse_category = []
      @warehouse_category << {category: "warehouses", name: "create", description: "Dar de alta un almacén"}
      @warehouse_category << {category: "warehouses", name: "show", description: "Mostrar información de los almacenes"}
      @warehouse_category << {category: "warehouses", name: "update_regions", description: "Modificar zonas de distribución"}
      @warehouse_category << {category: "warehouses", name: "update_warehouse_data", description: "Modificar información de almacenes"}
      @warehouse_category << {category: "warehouses", name: "update_wholesale", description: "Modificar coste de mayoreo"}
      @warehouse_category << {category: "warehouses", name: "delete", description: "Eliminar almacenes"}

      @parcel_category = []
      @parcel_category << {category: "parcels", name: "create", description: "Dar de alta paquetería"}
      @parcel_category << {category: "parcels", name: "delete", description: "Eliminar paqueterías"}
      @parcel_category << {category: "parcels", name: "update", description: "Modificar información de paqueterías"}

      @warehouse_product_category = []
      @warehouse_product_category << {category: "warehouse_products", name: "show", description: "Visualizar productos de almacén"}
      @warehouse_product_category << {category: "warehouse_products", name: "create_shipments", description: "Enviar productos a Almacén"}
      @warehouse_product_category << {category: "warehouse_products", name: "delete_shipments", description: "Eliminar envíos"}
      @warehouse_product_category << {category: "warehouse_products", name: "reject_shipment_stock", description: "Modificar existencias de almacén por diferencia de inventario"}
      @warehouse_product_category << {category: "warehouse_products", name: "update_min_stock", description: "Modificar cantidad de stock mínimo"}
      @warehouse_product_category << {category: "warehouse_products", name: "show_shipments", description: "Mostrar envíos del almacén"}
      @warehouse_product_category << {category: "warehouse_products", name: "batch_search", description: "Rastreo o búsqueda por lote"}
      @warehouse_product_category << {category: "warehouse_products", name: "inventory", description: "Impresión de inventario"}
      @warehouse_product_category << {category: "warehouse_products", name: "update_stock", description: "Modificar Stock"}

      @order_category = []
      @order_category << {category: "orders", name: "search", description: "Búsqueda de órdenes"}
      @order_category << {category: "orders", name: "show", description: "Ver detalles"}
      @order_category << {category: "orders", name: "cancel", description: "Cancelar orden"}
      @order_category << {category: "orders", name: "accept_reject_payment", description: "Aceptar o rechazar comprobante de pago"}
      @order_category << {category: "orders", name: "capture_batches", description: "Captura de No. de lotes"}
      @order_category << {category: "orders", name: "inspection", description: "Inspección del surtido"}
      @order_category << {category: "orders", name: "capture_tracking_code", description: "Captura de código de rastreo"}
      @order_category << {category: "orders", name: "stablish_as_sent", description: "Establecer como enviado"}
      @order_category << {category: "orders", name: "stablish_as_delivered", description: "Establecer como entregado/recibido"}
      @order_category << {category: "orders", name: "invoices", description: "Órdenes para facturar"}

      @other_category = []
      @other_category << {category: "product_questions", name: "answer", description: "Responder preguntas de producto"}
      @other_category << {category: "statistics", name: "show", description: "Ver estadísticas"}
      @other_category << {category: "clients", name: "show", description: "Ver clientes"}
      @other_category << {category: "clients", name: "supervisor_visit", description: "Fungir como supervisor (visitas de supervisor)"}
      @other_category << {category: "comments_and_suggestions", name: "answer", description: "Comentarios y sugerencias"}
      @other_category << {category: "tips_&_recipes", name: "all", description: "Tips y Recetas"}

      @web_category = []
      @web_category << {category: "web", name: "video", description: "Video"}
      @web_category << {category: "web", name: "gallery_images", description: "Galería / Imágenes"}
      @web_category << {category: "web", name: "offers", description: "Promociones"}
      @web_category << {category: "web", name: "texts", description: "Textos"}
      @web_category << {category: "web", name: "footer_details", description: "Detalles del pie de página"}
      @web_category << {category: "web", name: "social_networks", description: "Redes Sociales"}
      @web_category << {category: "web", name: "privacy_policy", description: "Aviso de Privacidad"}
      @web_category << {category: "web", name: "terms_of_service", description: "Términos y Condiciones"}

      @bank_category = []
      @bank_category << {category: "banks", name: "create", description: "Dar de alta bancos"}
      @bank_category << {category: "banks", name: "update", description: "Modificar bancos"}
      @bank_category << {category: "banks", name: "delete", description: "Eliminar bancos"}
      @bank_category << {category: "bank_accounts", name: "show", description: "Mostrar cuentas bancarias"}
      @bank_category << {category: "bank_accounts", name: "create", description: "Dar de alta cuentas bancarias"}
      @bank_category << {category: "bank_accounts", name: "update", description: "Modificar cuentas bancarias"}
      @bank_category << {category: "bank_accounts", name: "delete", description: "Eliminar cuentas bancarias"}

      @mexico_db_category = []
      @mexico_db_category << {category: "mexico_db", name: "update_state_LADA", description: "Editar LADA del estado"}
      @mexico_db_category << {category: "mexico_db", name: "update_city_name", description: "Editar nombre de población"}
      @mexico_db_category << {category: "mexico_db", name: "update_city_LADA", description: "Editar LADA de la población"}
      @mexico_db_category << {category: "mexico_db", name: "create", description: "Crear población y su LADA"}
    end
end
