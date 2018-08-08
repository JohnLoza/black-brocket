class Api::ProductsController < ApiController
  @@user_type = :client

  @@base_file_path = "app/views"
  @@replaceable_path = "/shared/products/"

  def index
    warehouse = @current_user.City.State.Warehouse

    if params[:category] and ["hot","cold","frappe"].include? params[:category]

      products = warehouse.Products.joins(:Product)
          .where(products:{
              show:true, deleted_at: nil, "#{params[:category]}" => true},
              describes_total_stock: true)
          .paginate(:page => params[:page], :per_page => 18).includes(:Product)

    elsif !params[:search].blank?

      products = warehouse.Products.joins(:Product)
          .where(products:{
              show:true, deleted_at: nil},
              describes_total_stock: true)
          .where("products.name like '%#{params[:search]}%'")
          .paginate(:page => params[:page], :per_page => 18).includes(:Product)

    else

      products = warehouse.Products.joins(:Product)
          .where(products:{
              show:true, deleted_at: nil},
              describes_total_stock: true)
          .paginate(:page => params[:page], :per_page => 18).includes(:Product)

    end

    photos = ProdPhoto.where("product_id in (?) and is_principal=true", products.map{|p| p.product_id})
    product_prices = @current_user.ProductPrices

    data = Array.new
    visit = @current_user.DistributorVisits.where(client_recognizes_visit: nil).take
    if !visit.blank?
      data<<{per_page: 18, new_visit: true, visit_id: visit.id, distributor_image: visit.Distributor.avatar_url(:mini),
        distributor_name: visit.Distributor.getName, visit_date: l(visit.visit_date, format: :long)}
    else
      data<<{per_page: 18, new_visit: false, visit_id: nil, distributor_image: nil, distributor_name: nil, visit_date: nil}
    end

    data << {user_data: {username: @current_user.username, photo: @current_user.getImage}}

    products.each do |w_product|
      p = w_product.Product
      sub_data = {hash_id: w_product.hash_id, name: p.name, price: p.price,
                  existence: w_product.existence, category_cold: p.cold,
                  category_hot: p.hot, category_frappe: p.frappe, p_key: p.hash_id}

      # get the photo for the product #
      photos.each do |photo|
        if photo.product_id == p.id
          sub_data[:photo] = photo.photo.url(:thumb)
          break
        end
      end

      # get the custom price if any #
      product_prices.each do |custom_price|
        if custom_price.product_id == p.id
          sub_data[:price] = custom_price.client_price
          break
        end
      end

      data << sub_data
    end

    render :status => 200,
           :json => { :success => true, :info => "PRODUCT_DATA", :data => data }
  end

  def show
    w_product = WarehouseProduct.find_by!(hash_id: params[:id])

    product = w_product.Product
    description_file = @@base_file_path + product.description_render_path.sub(@@replaceable_path, @@replaceable_path+'_')
    preparation_file = @@base_file_path + product.preparation_render_path.sub(@@replaceable_path, @@replaceable_path+'_')

    description = File.open(description_file, "r"){|file| file.read }
    preparation = File.open(preparation_file, "r"){|file| file.read }
    render :status => 200,
           :json => { :success => true, :info => "PRODUCT_DATA",
                      :data => { description: description,preparation: preparation,presentation: product.presentation}}
  end
end
