class Admin::ProductsController < AdminController
  @@base_file_path = "app/views"
  @@replaceable_path = "/shared/products/"

  def index
    deny_access! and return unless @current_user.has_permission_category?("products")
    @products = Product.active.order_by_name
      .search(key_words: search_params, fields: [:hash_id, :name])
      .paginate(page: params[:page], per_page: 20)
    @photos = ProdPhoto.by_product(@products.map(&:id).uniq).principal
  end

  def new
    deny_access! and return unless @current_user.has_permission?("products@create")
    @product = Product.new
  end

  def create
    deny_access! and return unless @current_user.has_permission?("products@create")
    @product = Product.new(product_params)

    if @product.save
      @product.update_attribute(:hash_id, generateAlphKey("P", @product.id))
      create_render_files_and_photos
      # create warehouse products based on current product
      create_warehouse_products
      # create product special prices slots for each user #
      create_client_prices

      redirect_to admin_products_path, flash: {success: "Producto creado" }
    else
      flash.now[:danger] = "Ocurrió un error al guardar los datos, inténtalo de nuevo por favor."
      render :new
    end
  end

  def show
    deny_access! and return unless @current_user.has_permission?("products@show")
    @product = Product.find_by!(hash_id: params[:id])
    @photos = @product.Photos
  end

  def edit
    unless @current_user.has_permission?("products@update_name") or
           @current_user.has_permission?("products@update_product_data") or
           @current_user.has_permission?("products@update_price") or
           @current_user.has_permission?("products@update_show_in_web_page")
      deny_access! and return
    end
    @product = Product.find_by!(hash_id: params[:id])

    description_file = @@base_file_path + @product.description_render_path.sub(@@replaceable_path, @@replaceable_path+"_")
    preparation_file = @@base_file_path + @product.preparation_render_path.sub(@@replaceable_path, @@replaceable_path+"_")

    @product.description = File.open(description_file, "r"){|file| file.read }
    @product.preparation = File.open(preparation_file, "r"){|file| file.read }

    @photos = @product.Photos
  end

  def update
    unless @current_user.has_permission?("products@update_name") or
           @current_user.has_permission?("products@update_product_data") or
           @current_user.has_permission?("products@update_price") or
           @current_user.has_permission?("products@update_show_in_web_page")
      deny_access! and return
    end
    @product = Product.find_by!(hash_id: params[:id])

    update_client_prices if prices_have_changed?
    if @product.update_attributes(product_params)
      create_render_files_and_photos

      flash[:success] = "El producto se actualizó."
      redirect_to admin_products_path
    else
      @photos = @product.Photos
      flash.now[:danger] = "Ocurrió un error al guardar los datos, inténtalo de nuevo por favor."
      render :edit
    end # if @product.update_attributes(product_params) #
  end

  def destroy
    deny_access! and return unless @current_user.has_permission?("products@delete")
    @product = Product.find_by!(hash_id: params[:id])

    if @product.destroy
      flash[:success] = "Producto eliminado"
    else
      flash[:info] = "Ocurrió un error al eliminar el trabajador, inténtalo de nuevo por favor."
    end
    redirect_to admin_products_path
  end

  def set_principal_photo
    deny_access! and return unless @current_user.has_permission?("products@update_product_data")
    @product = Product.find_by!(hash_id: params[:id])

    @photo = ProdPhoto.find_by!(hash_id: params[:photo_id])
    if @photo.product_id == @product.id
      ProdPhoto.by_product(@product.id).principal.take.update_attributes(is_principal: false)
      @photo.update_attributes(is_principal: true)
    end

    respond_to do |format|
      format.js { render :set_principal_photo, layout: false}
    end
  end

  def destroy_photo
    deny_access! and return unless @current_user.has_permission?("products@update_product_data")

    photo = ProdPhoto.find_by!(hash_id: params[:photo_id])
    photo.destroy

    respond_to do |format|
      format.js { render :destroy_photo, layout: false}
    end
  end

  private
    def product_params
      params.require(:product).permit(:name, :price, :show, :presentation, :total_weight,
        :hot, :cold, :frappe, :ieps, :iva, :lowest_price, :recommended_price, :video)
    end

    def main_photo_param
      params[:product][:principal_photo]
    end

    def photo_params
      return Array.new unless params[:product][:photo]
      params[:product][:photo]
    end

    def description_param
      params[:product][:description]
    end

    def preparation_param
      params[:product][:preparation]
    end

    def create_render_files_and_photos
      # create the files containing the description and preparation texts
      create_product_file(description_param, "description") if description_param
      create_product_file(preparation_param, "preparation") if preparation_param
      # create the main photo and other photos if any
      create_photo(photo: main_photo_param, principal: true) if main_photo_param
      photo_params.each do |photo|
        create_photo(photo: photo, principal: false)
      end
    end

    def create_product_file(text, file_attr_name)
      render_file_path = "#{@@replaceable_path}product_#{@product.hash_id}_#{file_attr_name}.html.erb"
      file_path = @@base_file_path + render_file_path.sub(@@replaceable_path, @@replaceable_path + "_")

      File.open(file_path, "w"){|file| file.write(text) }

      @product.update_attributes("#{file_attr_name}_render_path" => render_file_path)
    end

    def create_photo(options = {})
      return unless options[:photo].present?
      options[:principal] = false unless options[:principal].present?

      if options[:principal] == true
        current_principal = ProdPhoto.by_product(@product.id).principal.take
        current_principal.update_attributes(is_principal: false) if current_principal
      end
      ProdPhoto.create(product_id: @product.id, is_principal: options[:principal], photo: options[:photo])
    end

    def create_warehouse_products
      Warehouse.all.each do |w|
        WarehouseProduct.create(warehouse_id: w.id, describes_total_stock: true,
          product_id: @product.id, existence: 0, min_stock: 50)
      end
    end

    def create_client_prices
      clients = ClientProduct.select(:client_id).uniq
      clients.each do |client|
        ClientProduct.create(client_id: client.client_id, product_id: @product.id, client_price: @product.price)
      end
    end

    def update_client_prices
      client_products = ClientProduct.where(product_id: @product.id)
      client_products.update_all(client_price: params[:product][:price])
      clients = Client.where(deleted_at: nil)
      clients.each do |client|
        if client.has_custom_prices
          Notification.create(client_id: client.id, icon: "fa fa-comments-o", url: client_my_distributor_path,
            description: "El costo del producto #{@product.name} ha cambiado, favor de contactar a su distribuidor para negociar precio.")
        end
      end
    end

    def prices_have_changed?
      if @product.price != params[:product][:price].to_f or
        @product.recommended_price != params[:product][:recommended_price].to_f or
        @product.lowest_price != params[:product][:lowest_price].to_f
        return true
      end
      return false
    end

end
