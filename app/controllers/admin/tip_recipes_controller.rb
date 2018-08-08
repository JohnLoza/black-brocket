class Admin::TipRecipesController < AdminController
  @@base_file_path = "app/views"
  @@replaceable_path = "/shared/tips_recipes/"

  def index
    deny_access! and return unless @current_user.has_permission_category?('tips_&_recipes')

    @tips = TipRecipe.search(key_words: search_params, fields: ['title'])
      .recent.paginate(page: params[:page], per_page: 15)
  end

  def new
    deny_access! and return unless @current_user.has_permission_category?('tips_&_recipes')

    @tip = TipRecipe.new
  end

  def create
    deny_access! and return unless @current_user.has_permission_category?('tips_&_recipes')

    @tip =  TipRecipe.new(tip_recipe_params)

    render_file_path = @@replaceable_path + "tip_or_recipe_#{Time.now.to_i}.html.erb"
    file_path = @@base_file_path + render_file_path.sub(@@replaceable_path, @@replaceable_path + "_")

    file = File.open(file_path, "w")
    file.puts(params[:tip_recipe][:body])
    file.flush

    @tip.description_render_path = render_file_path

    if @tip.save
      flash[:success] = "Tip o Receta Guardada!"
    else
      flash[:info] = "Ocurrió un error al guardar..."
    end
    redirect_to admin_tip_recipes_path
  end

  def edit
    deny_access! and return unless @current_user.has_permission_category?('tips_&_recipes')

    @tip = TipRecipe.find_by!(id: params[:id])
    file_path = @@base_file_path + @tip.description_render_path.sub(@@replaceable_path, @@replaceable_path + '_')
    @tip.body = File.open(file_path, "r"){|file| file.read }
  end

  def update
    deny_access! and return unless @current_user.has_permission_category?('tips_&_recipes')

    @tip = TipRecipe.find_by!(id: params[:id])

    file_path = @@base_file_path + @tip.description_render_path.sub(@@replaceable_path, @@replaceable_path+'_')
    File.open(file_path, "w"){|file| file.write(params[:tip_recipe][:body]) }

    if @tip.update_attributes(tip_recipe_params)
      flash[:success] = "Tip o Receta Actualizada!"
    else
      flash[:info] = "Ocurrió un error al guardar..."
    end
    
    redirect_to admin_tip_recipes_path
  end

  def destroy
    deny_access! and return unless @current_user.has_permission_category?('tips_&_recipes')
    @tip = TipRecipe.find_by!(id: params[:id])

    if @tip.destroy
      flash[:success] = 'Tip/Receta eliminado'
    else
      flash[:warning] = 'Error al eliminar el tip o receta'
    end
    redirect_to admin_tip_recipes_path
  end

  private
    def tip_recipe_params
      params.require(:tip_recipe).permit(:title, :image, :video)
    end
end
