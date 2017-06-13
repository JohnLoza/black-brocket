class ChangeFieldsStoringHtmlToFilePath < ActiveRecord::Migration
  def change
    # this fields containt html, we're moving out that html to files #
    WebInfo.all.update_all(description: "")
    Product.all.update_all(description: "")
    Product.all.update_all(preparation: "")
    TipRecipe.all.update_all(description: "")

    # so, now the field will contain the path used by "render" #
    # (it means without the starting underscore in the file name) #
    rename_column :web_infos, :description, :description_render_path
    change_column :web_infos, :description_render_path, :string

    rename_column :products, :description, :description_render_path
    change_column :products, :description_render_path, :string

    rename_column :products, :preparation, :preparation_render_path
    change_column :products, :preparation_render_path, :string

    rename_column :tip_recipes, :description, :description_render_path
    change_column :tip_recipes, :description_render_path, :string

    # generate files for the current existing products #
    Product.all.each do |product|
      base_file_path = "app/views"
      replaceable_path = "/shared/products/"

      render_file_path = replaceable_path + "product_" + product.alph_key + "_description.html.erb"
      file_path = base_file_path + render_file_path.sub(replaceable_path, replaceable_path + "_")

      file = File.open(file_path, "w")
      file.puts("<p>Editame...</p>")
      file.flush

      product.update_attributes(:description_render_path => render_file_path)

      render_file_path = replaceable_path + "product_" + product.alph_key + "_preparation.html.erb"
      file_path = base_file_path + render_file_path.sub(replaceable_path, replaceable_path + "_")

      file = File.open(file_path, "w")
      file.puts("<p>Editame...</p>")
      file.flush

      product.update_attributes(:preparation_render_path => render_file_path)
    end

    WebInfo.all.each do |info|
      info.update_attribute(:description_render_path, "/shared/web/init_file.html.erb")
    end
  end
end
