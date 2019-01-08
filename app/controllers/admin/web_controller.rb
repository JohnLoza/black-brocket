class Admin::WebController < AdminController
  @@base_file_path = "app/views"
  @@replaceable_path = "/shared/web/"

  def index
    deny_access! and return unless @current_user.has_permission_category?('web')
  end

  def photos
    deny_access! and return unless @current_user.has_permission?('web@gallery_images')

    @photos = WebPhoto.where(name: "GALLERY")
    @log_in_initial = WebPhoto.where.not(name: "GALLERY")
    @new_photo = WebPhoto.new
  end

  def upload_photos
    deny_access! and return unless @current_user.has_permission?('web@gallery_images')

    success = true

    params[:web_photo][:photos].each do |p|
      photo = WebPhoto.new({ photo: p, name: params[:web_photo][:name] })
      success = false if !photo.save
    end if params[:web_photo][:photos]

    if params[:web_photo][:photo]
      p = WebPhoto.where(name: params[:web_photo][:name]).take

      if p.blank?
        photo = WebPhoto.new({ photo: params[:web_photo][:photo], name: params[:web_photo][:name] })
        success = false if !photo.save
      else
        p.photo = params[:web_photo][:photo]
        success = false if !p.save
      end

    end

    if success
      type = :success
      message = "Imágenes cargadas al sitio"
    else
      type = :danger
      message = "Alguna o todas las imágenes no han podido ser cargadas, verifica que las imágenes sean del formato correcto, jpg, jpeg, png"
    end

    flash[type] = message
    redirect_to admin_web_photos_path
  end

  def destroy_photo
    deny_access! and return unless @current_user.has_permission?('web@gallery_images')

    photo = WebPhoto.find_by!(id: params[:id])
    if photo.destroy
      flash[:success] = "Imagen eliminada"
    else
      flash[:info] = "La imagen no se pudo eliminar"
    end

    redirect_to admin_web_photos_path
  end

  def offers
    deny_access! and return unless @current_user.has_permission?('web@offers')

    @offers = WebOffer.all
    @new_offer = WebOffer.new
  end

  def upload_offers
    deny_access! and return unless @current_user.has_permission?('web@offers')

    offer = WebOffer.new(web_offer_params)

    if offer.save
      flash[:success] = "Imágenes cargadas al sitio"
    else
      flash[:info] = "Alguna o todas las imágenes no han podido ser cargadas, verifica que las imágenes sean del formato correcto, jpg, jpeg, png"
    end

    redirect_to admin_web_offers_path
  end

  def destroy_offer
    deny_access! and return unless @current_user.has_permission?('web@offers')

    offer = WebOffer.find_by!(id: params[:id])
    if offer.destroy
      flash[:success] = "Imagen eliminada"
    else
      flash[:info] = "La imagen no se pudo eliminar"
    end

    redirect_to admin_web_offers_path
  end

  def edit_info
    case params[:name]
    when 'TERMS_OF_SERVICE'
      deny_access! and return unless @current_user.has_permission?('web@terms_of_service')
    when 'PRIVACY_POLICY'
      deny_access! and return unless @current_user.has_permission?('web@privacy_policy')
    else
      deny_access! and return unless @current_user.has_permission?('web@texts')
    end

    @web_info = WebInfo.where(name: params[:name]).take
    if @web_info
      # adding the starting underscore to the file name as it is stored without it to use with "render" in views #
      file_path = @web_info.description_render_path.sub(@@replaceable_path, @@replaceable_path + '_')
      @web_info.body = File.open(@@base_file_path + file_path, "r"){|file| file.read }
    end
  end

  def update_info
    case params[:name]
    when 'TERMS_OF_SERVICE'
      deny_access! and return unless @current_user.has_permission?('web@terms_of_service')
    when 'PRIVACY_POLICY'
      deny_access! and return unless @current_user.has_permission?('web@privacy_policy')
    else
      deny_access! and return unless @current_user.has_permission?('web@texts')
    end

    web_info = WebInfo.where(name: params[:name]).take
    if !web_info.blank?
      render_file_path = @@replaceable_path + params[:name].downcase + ".html.erb"
      file_path = @@base_file_path + render_file_path.sub(@@replaceable_path, @@replaceable_path + "_")

      # erasing contents of file and openning it to rewrite, to append use "a" as second argument #
      File.open(file_path, "w"){|file| file.write(params[:web_info][:body]) }

      web_info.update_attributes(:description_render_path => render_file_path) if web_info.description_render_path != render_file_path
      flash[:success] = t(params[:name]) + " actualizado!"
    else
      flash[:info] = "La página que buscas, no existe..."
    end
    redirect_to admin_web_path
  end

  def videos
    deny_access! and return unless @current_user.has_permission?('web@video')

    @video = WebVideo.first
    @video = WebVideo.new if !@video
  end

  def upload_video
    deny_access! and return unless @current_user.has_permission?('web@video')

    @video = WebVideo.first
    if @video
      if @video.update_attributes(video: params[:web_video][:video])
        flash[:success] = "Video actualizado"
      else
        flash[:info] = "Ocurrió un error, recuerda que el video debe ser mp4"
      end
    else
      @video = WebVideo.new({ video: params[:web_video][:video] })
      if @video.save
        flash[:success] = "Video actualizado"
      else
        flash[:info] = "Ocurrió un error, recuerda que el video debe ser mp4"
      end
    end

    redirect_to admin_web_videos_path
  end

  def reset_videos
    deny_access! and return unless @current_user.has_permission?('web@video')

    video = WebVideo.first
    video.destroy if video

    redirect_to admin_web_videos_path
  end

  def social_networks
    deny_access! and return unless @current_user.has_permission?('web@social_networks')

    @networks = SocialNetwork.all
  end

  def update_social_networks
    deny_access! and return unless @current_user.has_permission?('web@social_networks')

    @network = SocialNetwork.find_by!(id: params[:id])
    if @network.update_attributes(url: params[:social_network][:url])
      flash[:success] = @network.name + " actualizado"
    else
      flash[:info] = "Error al actualizar, inténtelo de nuevo por favor."
    end

    redirect_to admin_web_social_networks_path
  end

  def footer_details
    deny_access! and return unless @current_user.has_permission?('web@footer_details')

    @details = FooterExtraDetail.all
  end

  def create_footer_detail
    deny_access! and return unless @current_user.has_permission?('web@footer_details')

    detail = FooterExtraDetail.new(footer_params)
    if detail.save
      flash[:success] = "Detalle guardado!"
    else
      flash[:info] = "Ocurrió un error al guardar"
    end

    redirect_to admin_web_footer_details_path
  end

  def delete_footer_detail
    deny_access! and return unless @current_user.has_permission?('web@footer_details')

    detail = FooterExtraDetail.find_by!(id: params[:id])

    detail.destroy
    flash[:success] = "Detalle eliminado!"
    redirect_to admin_web_footer_details_path
  end

  def services
    deny_access! and return unless @current_user.has_permission?('web@texts')

    @infos = WebInfo.where(name: ["HIGH_QUALITY","DISCOUNTS","EASY_SHOPPING","DISTRIBUTORS"])
    @infos.each do |info|
      # adding the starting underscore to the file name as it is stored without it to use with "render" in views #
      file_path = info.description_render_path.sub(@@replaceable_path, @@replaceable_path + '_')
      info.body = File.open(@@base_file_path + file_path, "r"){|file| file.read }
    end
  end

  def update_services
    deny_access! and return unless @current_user.has_permission?('web@texts')

    web_info = WebInfo.find(params[:id])
    if !web_info.blank?
      render_file_path = @@replaceable_path + web_info.name.downcase + ".html.erb"
      file_path = @@base_file_path + render_file_path.sub(@@replaceable_path, @@replaceable_path + "_")

      # erasing contents of file and openning it to rewrite, to append use "a" as second argument #
      File.open(file_path, "w"){|file| file.write(params[:web_info][:body]) }

      web_info.update_attributes(:description_render_path => render_file_path) if web_info.description_render_path != render_file_path
      flash[:success] = "Servicio actualizado!"
    else
      flash[:info] = "La página que buscas, no existe..."
    end
    redirect_to admin_web_services_path
  end

  private
    def footer_params
      params.require(:footer_extra_detail).permit(:name, :detail)
    end

    def web_offer_params
      params.require(:web_offer).permit(:photo, :url)
    end
end
