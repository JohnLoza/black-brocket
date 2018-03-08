class Admin::TipsController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_worker?
  layout "admin_layout.html.erb"

  @@category = "TIPS_&_RECIPES"

  @@base_file_path = "app/views"
  @@replaceable_path = "/shared/tips_recipes/"

  def index
    authorization_result = current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @tips = TipRecipe.all.order(created_at: :desc).paginate(page: params[:page], per_page: 15)
  end

  def new
    authorization_result = current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @tip = TipRecipe.new
    @url = admin_tips_path
  end

  def create
    authorization_result = current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @tip =  TipRecipe.new(tip_recipe_params)
    if params[:tip_recipe] and params[:tip_recipe][:multimedia]
      content_type = params[:tip_recipe][:multimedia].content_type
      if content_type.include? "video"
        @tip.video = params[:tip_recipe][:multimedia]
        @tip.video_type = "LOCAL_VIDEO"
      elsif content_type.include? "image"
        @tip.image = params[:tip_recipe][:multimedia]
      end
    end

    render_file_path = @@replaceable_path + "tip_or_recipe_#{Time.now.to_i}_#{rand(10..99)}.html.erb"
    # The render_file_path should not have the starting underscore, but #
    # as we are generating the real file_path we need to add it, just for that #
    file_path = @@base_file_path + render_file_path.sub(@@replaceable_path, @@replaceable_path + "_")

    # erasing contents of file and openning it to rewrite, to append use "a" as second argument #
    file = File.open(file_path, "w")
    file.puts(params[:tip_recipe][:body])
    file.flush

    @tip.description_render_path = render_file_path

    if @tip.save
      flash[:success] = "Tip o Receta Guardada!"
    else
      flash[:info] = "Ocurrió un error al guardar..."
    end
    redirect_to admin_tips_path
  end

  def edit
    authorization_result = current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @tip = TipRecipe.find_by(id: params[:id])
    if @tip.nil?
      flash[:info] = "No se encontró el tip con clave: #{params[:id]}"
      redirect_to admin_tips_path
      return
    end

    file_path = @@base_file_path + @tip.description_render_path.sub(@@replaceable_path, @@replaceable_path + '_')
    if !File.exists?(file_path)
      File.open(file_path, "w"){|file| file.write("<h1>Tip and or Recipe</h1><p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis facilisis tempor libero quis sollicitudin. Sed volutpat risus nibh, vel scelerisque nunc dapibus ac. Cras porta magna lobortis, rutrum ante ac, viverra justo. Vivamus sed orci risus. Quisque viverra eros leo, quis fermentum ante cursus id. Integer urna ligula, dapibus id purus id, tempus porta magna. Pellentesque ut purus ultrices, tincidunt odio nec, sollicitudin arcu. Nulla dui turpis, sodales quis dui sed, consectetur vestibulum lorem. Maecenas libero lacus, pellentesque non arcu non, facilisis suscipit massa.</p>") }
    end

    @tip.body = File.open(file_path, "r"){|file| file.read }

    @url = admin_tip_path(@tip.id)
  end

  def update
    authorization_result = current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @tip = TipRecipe.find_by(id: params[:id])
    if @tip.nil?
      flash[:info] = "No se encontró el tip con clave: #{params[:id]}"
      redirect_to admin_tips_path
      return
    end

    @tip.title = params[:tip_recipe][:title]

    if params[:tip_recipe] and params[:tip_recipe][:multimedia]
      content_type = params[:tip_recipe][:multimedia].content_type
      if content_type.include? "video"
        @tip.video = params[:tip_recipe][:multimedia]
        @tip.video_type = "LOCAL_VIDEO"
        @tip.remove_image!
      elsif content_type.include? "image"
        @tip.image = params[:tip_recipe][:multimedia]
        @tip.remove_video!
      end
    end

    file_path = @@base_file_path + @tip.description_render_path.sub(@@replaceable_path, @@replaceable_path+'_')
    File.open(file_path, "w"){|file| file.write(params[:tip_recipe][:body]) }

    if @tip.save
      flash[:success] = "Tip o Receta Actualizada!"
    else
      flash[:info] = "Ocurrió un error al guardar..."
    end
    redirect_to admin_tips_path
  end

  private
    def tip_recipe_params
      params.require(:tip_recipe).permit(:title)
    end
end
