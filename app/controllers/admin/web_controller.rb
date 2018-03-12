class Admin::WebController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_worker?
  layout "admin_layout.html.erb"

  @@category = "WEB"

  @@base_file_path = "app/views"
  @@replaceable_path = "/shared/web/"

  def index
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    # determine the actions the user can do, so we can display them in screen #
    @actions = {"VIDEO"=>false,"GALLERY_IMAGES"=>false,"OFFERS"=>false,"TEXTS"=>false,"SOCIAL_NETWORKS"=>false,"PRIVACY_POLICY"=>false,"TERMS_OF_SERVICE"=>false,"FOOTER_DETAILS"=>false}
    if !@current_user.is_admin
      @user_permissions.each do |p|
        # see if the permission category is equal to the one we need in these controller #
        if p.category == @@category
          @actions[p.name]=true
        end # if p.category == @@category #
      end # @user_permissions.each end #
    else
      @actions = {"VIDEO"=>true,"GALLERY_IMAGES"=>true,"OFFERS"=>true,"TEXTS"=>true,"SOCIAL_NETWORKS"=>true,"PRIVACY_POLICY"=>true,"TERMS_OF_SERVICE"=>true,"FOOTER_DETAILS"=>true}
    end # if !@current_user.is_admin end #
  end

  def photos
    authorization_result = @current_user.is_authorized?(@@category, "GALLERY_IMAGES")
    return if !process_authorization_result(authorization_result)

    @photos = WebPhoto.where(name: "GALLERY")
    @log_in_initial = WebPhoto.where('name != "GALLERY"')
    @new_photo = WebPhoto.new
  end

  def upload_photos
    authorization_result = @current_user.is_authorized?(@@category, "GALLERY_IMAGES")
    return if !process_authorization_result(authorization_result)

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
    authorization_result = @current_user.is_authorized?(@@category, "GALLERY_IMAGES")
    return if !process_authorization_result(authorization_result)

    photo = WebPhoto.find(params[:id])
    if photo and photo.destroy
      flash[:success] = "Imagen eliminada"
    else
      flash[:danger] = "La imagen no se pudo eliminar"
    end

    redirect_to admin_web_photos_path
  end

  def offers
    authorization_result = @current_user.is_authorized?(@@category, "OFFERS")
    return if !process_authorization_result(authorization_result)

    @offers = WebOffer.all
    @new_offer = WebOffer.new
  end

  def upload_offers
    authorization_result = @current_user.is_authorized?(@@category, "OFFERS")
    return if !process_authorization_result(authorization_result)

    photo = WebOffer.new({ photo: params[:web_offer][:offer],
                           url: params[:web_offer][:url] })
    success = true if photo.save

    if success
      type = :success
      message = "Imágenes cargadas al sitio"
    else
      type = :danger
      message = "Alguna o todas las imágenes no han podido ser cargadas, verifica que las imágenes sean del formato correcto, jpg, jpeg, png"
    end

    flash[type] = message
    redirect_to admin_web_offers_path
  end

  def destroy_offer
    authorization_result = @current_user.is_authorized?(@@category, "OFFERS")
    return if !process_authorization_result(authorization_result)

    photo = WebOffer.find(params[:id])
    if photo and photo.destroy
      flash[:success] = "Imagen eliminada"
    else
      flash[:danger] = "La imagen no se pudo eliminar"
    end

    redirect_to admin_web_offers_path
  end

  def edit_info
    permission_name = params[:name]
    permission_name = "TEXTS" if permission_name == "WELCOME_MESSAGE" or permission_name == "ECART_NOTICE"

    authorization_result = @current_user.is_authorized?(@@category, permission_name)
    return if !process_authorization_result(authorization_result)

    @web_info = WebInfo.where(name: params[:name]).take
    if @web_info
      # adding the starting underscore to the file name as it is stored without it to use with "render" in views #
      file_path = @web_info.description_render_path.sub(@@replaceable_path, @@replaceable_path + '_')
      @web_info.body = File.open(@@base_file_path + file_path, "r"){|file| file.read }
    end
  end

  def update_info
    permission_name = params[:name]
    permission_name = "TEXTS" if permission_name == "WELCOME_MESSAGE" or permission_name == "ECART_NOTICE"

    authorization_result = @current_user.is_authorized?(@@category, permission_name)
    return if !process_authorization_result(authorization_result)

    web_info = WebInfo.where(name: params[:name]).take
    if !web_info.blank?
      render_file_path = @@replaceable_path + params[:name].downcase + ".html.erb"
      # The render_file_path should not have the starting underscore, but #
      # as we are generating the real file_path we need to add it, just for that #
      file_path = @@base_file_path + render_file_path.sub(@@replaceable_path, @@replaceable_path + "_")

      # erasing contents of file and openning it to rewrite, to append use "a" as second argument #
      file = File.open(file_path, "w")
      file.puts(params[:web_info][:body])
      file.flush

      web_info.update_attributes(:description_render_path => render_file_path) if web_info.description_render_path != render_file_path
      flash[:success]= t(params[:name]) + " actualizado!"
    else
      flash[:info] = "La página que buscas, no existe..."
    end
    redirect_to admin_web_path
  end

  def videos
    authorization_result = @current_user.is_authorized?(@@category, "VIDEO")
    return if !process_authorization_result(authorization_result)

    @video = WebVideo.first
    @video = WebVideo.new if !@video
  end

  def upload_video
    authorization_result = @current_user.is_authorized?(@@category, "VIDEO")
    return if !process_authorization_result(authorization_result)

    @video = WebVideo.first
    if @video
      if @video.update_attributes(video: params[:web_video][:video])
        flash_type = :success
        message = "Video actualizado"
      else
        flash_type = :danger
        message = "Ocurrió un error, recuerda que el video debe ser mp4"
      end
    else
      @video = WebVideo.new({ video: params[:web_video][:video] })
      if @video.save
        flash_type = :success
        message = "Video actualizado"
      else
        flash_type = :danger
        message = "Ocurrió un error, recuerda que el video debe ser mp4"
      end
    end

    flash[flash_type] = message
    redirect_to admin_web_videos_path
  end

  def reset_videos
    authorization_result = @current_user.is_authorized?(@@category, "VIDEO")
    return if !process_authorization_result(authorization_result)

    video = WebVideo.first
    video.destroy if video

    redirect_to admin_web_videos_path
  end

  def social_networks
    authorization_result = @current_user.is_authorized?(@@category, "SOCIAL_NETWORKS")
    return if !process_authorization_result(authorization_result)

    @networks = SocialNetwork.all
  end

  def update_social_networks
    authorization_result = @current_user.is_authorized?(@@category, "SOCIAL_NETWORKS")
    return if !process_authorization_result(authorization_result)

    @network = SocialNetwork.find(params[:id])
    if @network
      if @network.update_attributes(url: params[:social_network][:url])
        flash[:success] = @network.name + " actualizado"
      else
        flash[:danger] = "Error al actualizar, inténtelo de nuevo por favor."
      end
    end

    redirect_to admin_web_social_networks_path
  end

  def footer_details
    authorization_result = @current_user.is_authorized?(@@category, "FOOTER_DETAILS")
    return if !process_authorization_result(authorization_result)

    @details = FooterExtraDetail.all
  end

  def create_footer_detail
    authorization_result = @current_user.is_authorized?(@@category, "FOOTER_DETAILS")
    return if !process_authorization_result(authorization_result)

    detail = FooterExtraDetail.new(footer_params)
    saved=false
    if detail.save
      saved=true
    end

    flash[:success] = "Detalle guardado!" if saved
    flash[:danger] = "Ocurrió un error al guardar" if !saved
    redirect_to admin_web_footer_details_path
  end

  def delete_footer_detail
    authorization_result = @current_user.is_authorized?(@@category, "FOOTER_DETAILS")
    return if !process_authorization_result(authorization_result)

    detail = FooterExtraDetail.find(params[:id])
    if detail.nil?
      flash[:warning] = "No se encontró el detalle"
      redirect_to admin_web_footer_details_path
      return
    end

    detail.destroy
    flash[:success] = "Detalle eliminado!"
    redirect_to admin_web_footer_details_path
  end

  def services
    authorization_result = @current_user.is_authorized?(@@category, "TEXTS")
    return if !process_authorization_result(authorization_result)

    @infos = WebInfo.where(name: ["HIGH_QUALITY","DISCOUNTS","EASY_SHOPPING","DISTRIBUTORS"])
    @infos.each do |info|
      # adding the starting underscore to the file name as it is stored without it to use with "render" in views #
      file_path = info.description_render_path.sub(@@replaceable_path, @@replaceable_path + '_')
      info.body = File.open(@@base_file_path + file_path, "r"){|file| file.read }
    end
  end

  def update_services
    authorization_result = @current_user.is_authorized?(@@category, "TEXTS")
    return if !process_authorization_result(authorization_result)

    web_info = WebInfo.find(params[:id])
    if !web_info.blank?
      render_file_path = @@replaceable_path + web_info.name.downcase + ".html.erb"
      # The render_file_path should not have the starting underscore, but #
      # as we are generating the real file_path we need to add it, just for that #
      file_path = @@base_file_path + render_file_path.sub(@@replaceable_path, @@replaceable_path + "_")

      # erasing contents of file and openning it to rewrite, to append use "a" as second argument #
      file = File.open(file_path, "w")
      file.puts(params[:web_info][:body])
      file.flush

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
end
