class Admin::ProductsController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_worker?
  layout "admin_layout.html.erb"

  @@category = "PRODUCTS"

  @@base_file_path = "app/views"
  @@replaceable_path = "/shared/products/"

  def index
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    if search_params
      @products = Product.search(search_params, params[:page])
    else
      @products = Product.show_admin(params[:page])
    end

    @photos = ProdPhoto.where("product_id in (?) and is_principal=true", @products.map{|p| p.id})

    # determine the actions the user can do, so we can display them in screen #
    @actions = {"SHOW"=>false,"CREATE"=>false,"DELETE"=>false,"UPDATE"=>false}
    if !@current_user.is_admin
      @user_permissions.each do |p|
        # see if the permission category is equal to the one we need in these controller #
        if p.category == @@category
          case p.name
          when "SHOW"
            @actions[p.name]=true
          when "CREATE"
            @actions[p.name]=true
          when "DELETE"
            @actions[p.name]=true
          when "UPDATE_NAME", "UPDATE_PRODUCT_DATA", "UPDATE_PRICE", "UPDATE_SHOW_IN_WEB_PAGE"
            @actions["UPDATE"]=true
          end # case p.name end #
        end # if p.category == @@category #
      end # @user_permissions.each end #
    else
      @actions = {"SHOW"=>true,"CREATE"=>true,"DELETE"=>true,"UPDATE"=>true}
    end # if !@current_user.is_admin end #
  end

  def new
    authorization_result = @current_user.is_authorized?(@@category, "CREATE")
    return if !process_authorization_result(authorization_result)

    _new()
    @product = Product.new
  end

  def create
    authorization_result = @current_user.is_authorized?(@@category, "CREATE")
    return if !process_authorization_result(authorization_result)

    @product = Product.new(product_params)
    @product.name.strip!

    if @product.save
      @product.update_attribute(:alph_key, generateAlphKey("P", @product.id))
      if params[:product][:description_body]
        render_file_path = @@replaceable_path + "product_" + @product.alph_key + "_description.html.erb"
        file_path = @@base_file_path + render_file_path.sub(@@replaceable_path, @@replaceable_path + "_")

        file = File.open(file_path, "w")
        file.puts(params[:product][:description_body])
        file.flush

        @product.update_attributes(:description_render_path => render_file_path)
      end
      if params[:product][:preparation_body]
        render_file_path = @@replaceable_path + "product_" + @product.alph_key + "_preparation.html.erb"
        file_path = @@base_file_path + render_file_path.sub(@@replaceable_path, @@replaceable_path + "_")

        file = File.open(file_path, "w")
        file.puts(params[:product][:preparation_body])
        file.flush

        @product.update_attributes(:preparation_render_path => render_file_path)
      end

      if params[:product][:principal_photo]
        ProdPhoto.where("product_id=#{@product.id} and is_principal=true").limit(1).update_all(is_principal: false)
        ProdPhoto.create(product_id: @product.id, is_principal: true,
                         alph_key: SecureRandom.urlsafe_base64(6),
                         photo: params[:product][:principal_photo],)
      end

      image_params.each do |param|
        @new_photo = ProdPhoto.create(product_id: @product.id,
                               alph_key: SecureRandom.urlsafe_base64(6),
                               photo: param)
      end if image_params

      Warehouse.all.each do |w|
        WarehouseProduct.create(warehouse_id: w.id, describes_total_stock: true,
                product_id: @product.id, existence: 0, min_stock: 50,
                alph_key: SecureRandom.urlsafe_base64(6))
      end

      # set new custom_prices #
      clients = ClientProduct.select(:client_id).uniq
      clients.each do |client|
        ClientProduct.create(client_id: client.client_id, product_id: @product.id, client_price: @product.price)
      end

      redirect_to controller: "admin/products"
    else
      _new()
      flash.now[:danger] = 'Ocurrió un error al guardar los datos, intentalo de nuevo por favor.'
      render :new
    end
  end

  def show
    authorization_result = @current_user.is_authorized?(@@category, "SHOW")
    return if !process_authorization_result(authorization_result)

    @product = Product.find_by(alph_key: params[:id])
    if @product.nil?
      flash[:info] = "No se encontró el producto con clave: #{params[:id]}"
      redirect_to admin_products_path
      return
    end

    @photos = @product.Photos
  end

  def edit
    authorization_result = @current_user.is_authorized?(@@category, ["UPDATE_NAME", "UPDATE_PRODUCT_DATA",
                                      "UPDATE_PRICE", "UPDATE_SHOW_IN_WEB_PAGE"])
    return if !process_authorization_result(authorization_result)

    @product = Product.find_by(alph_key: params[:id])
    if !@product.nil?
      description_file = @@base_file_path + @product.description_render_path.sub(@@replaceable_path, @@replaceable_path+'_')
      preparation_file = @@base_file_path + @product.preparation_render_path.sub(@@replaceable_path, @@replaceable_path+'_')

      @product.description_body = File.open(description_file, "r"){|file| file.read }
      @product.preparation_body = File.open(preparation_file, "r"){|file| file.read }
    else
      flash[:info] = "No se encontró el producto con clave: #{params[:id]}"
      redirect_to admin_products_path
      return
    end

    _edit()
  end

  def update
    authorization_result = @current_user.is_authorized?(@@category, ["UPDATE_NAME", "UPDATE_PRODUCT_DATA",
                                      "UPDATE_PRICE", "UPDATE_SHOW_IN_WEB_PAGE"])
    return if !process_authorization_result(authorization_result)

    @product = Product.find_by(alph_key: params[:id])
    if @product.nil?
      flash[:info] = "No se encontró el producto con clave: #{params[:id]}"
      redirect_to admin_products_path
      return
    end

    if @product.price != params[:product][:price].to_i or
       @product.recommended_price != params[:product][:recommended_price].to_i or
       @product.lowest_price != params[:product][:lowest_price].to_i
       puts "--- prices changed ---"
       client_products = ClientProduct.where(product_id: @product.id)
       client_products.update_all(client_price: params[:product][:price])
       clients = Client.where(deleted: false)
       clients.each do |client|
         if client.has_custom_prices
           Notification.create(client_id: client.id, icon: "fa fa-comments-o",
                           description: "El costo del producto #{@product.name} ha cambiado, favor de contactar a su distribuidor para negociar precio.",
                           url: client_my_distributor_path)
         end
       end
    end

    if @product.update_attributes(product_params)
      if params[:product][:description_body]
        render_file_path = @@replaceable_path + "product_" + @product.alph_key + "_description.html.erb"
        file_path = @@base_file_path + render_file_path.sub(@@replaceable_path, @@replaceable_path + "_")

        file = File.open(file_path, "w")
        file.puts(params[:product][:description_body])
        file.flush

        @product.update_attributes(:description_render_path => render_file_path)
      end
      if params[:product][:preparation_body]
        render_file_path = @@replaceable_path + "product_" + @product.alph_key + "_preparation.html.erb"
        file_path = @@base_file_path + render_file_path.sub(@@replaceable_path, @@replaceable_path + "_")

        file = File.open(file_path, "w")
        file.puts(params[:product][:preparation_body])
        file.flush

        @product.update_attributes(:preparation_render_path => render_file_path)
      end

      if params[:product][:principal_photo]
        ProdPhoto.where(product_id: @product.id, is_principal: true).limit(1).update_all(is_principal: false)
        ProdPhoto.create(product_id: @product.id, is_principal: true,
                         alph_key: SecureRandom.urlsafe_base64(6),
                         photo: params[:product][:principal_photo],)
      end

      image_params.each do |param|
        @new_photo = ProdPhoto.create(product_id: @product.id,
                            alph_key: SecureRandom.urlsafe_base64(6),
                            photo: param)
      end if image_params
      flash[:success] = "El producto se actualizó."
      redirect_to controller: "admin/products"
      return
    else
      _edit()
      flash.now[:danger] = 'Ocurrió un error al guardar los datos, intentalo de nuevo por favor.'
      render :edit
    end # if @product.update_attributes(product_params) #
  end

  def destroy
    authorization_result = @current_user.is_authorized?(@@category, "DELETE")
    return if !process_authorization_result(authorization_result)

    @product = Product.find_by(alph_key: params[:id])
    if @product.nil?
      flash[:info] = "No se encontró el producto con clave: #{params[:id]}"
      redirect_to admin_products_path
      return
    end

    if @product.update_attributes(:deleted => true)
      redirect_to controller: "admin/products"
    else
      flash[:danger] = 'Ocurrió un error al eliminar el trabajador, intentalo de nuevo por favor.'
      redirect_to controller: "admin/products"
    end
  end

  def set_principal_photo
    authorization_result = @current_user.is_authorized?(@@category, "UPDATE_PRODUCT_DATA")
    return if !process_authorization_result(authorization_result)

    product_id = Product.find_by(alph_key: params[:id]).id

    ProdPhoto.where("product_id=#{product_id} and is_principal=true").limit(1).update_all(is_principal: false)
    ProdPhoto.where("product_id=#{product_id} and alph_key='#{params[:photo_id]}'").limit(1).update_all(is_principal: true)

    respond_to do |format|
      format.js { render :set_principal_photo, layout: false}
    end
  end

  def destroy_photo
    authorization_result = @current_user.is_authorized?(@@category, "UPDATE_PRODUCT_DATA")
    return if !process_authorization_result(authorization_result)

    photo = ProdPhoto.find_by(alph_key: params[:photo_id])
    photo.destroy

    respond_to do |format|
      format.js { render :destroy_photo, layout: false}
    end
  end

  private
    def product_params
      params.require(:product).permit(:name, :price, :show,
                                      :hot, :cold, :frappe, :ieps, :iva,
                                      :lowest_price, :video,
                                      :presentation, :recommended_price)
    end

    def image_params
      params[:product][:photo]
    end

    def search_params
      params[:product][:search] if params[:product]
    end

    def _new
      @url = admin_products_path

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
      @url = admin_product_path(params[:id])
      @photos = @product.Photos

      # see if has permission to update #
      @actions = {"UPDATE_NAME"=>false, "UPDATE_PRODUCT_DATA"=>false, "UPDATE_PRICE"=>false, "UPDATE_SHOW_IN_WEB_PAGE"=>false}
      if !@current_user.is_admin
        @user_permissions.each do |p|
          # see if the permission category is equal to the one we need in these controller #
          if p.category == @@category
            if ["UPDATE_NAME", "UPDATE_PRODUCT_DATA", "UPDATE_PRICE",
                "UPDATE_SHOW_IN_WEB_PAGE"].include? p.name
              @actions[p.name] = true
            end
          end # if p.category == @@category #
        end # @user_permissions.each end #
      else
        @actions = {"UPDATE_NAME"=>true, "UPDATE_PRODUCT_DATA"=>true, "UPDATE_PRICE"=>true, "UPDATE_SHOW_IN_WEB_PAGE"=>true}
      end # if !@current_user.is_admin end #
    end
end
