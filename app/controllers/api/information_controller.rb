class Api::InformationController < ApiController

  before_action only: :ecart_info do
    authenticate_user!(Client)
  end
  
  @@base_file_path = "app/views"
  @@replaceable_path = "/shared/tips_recipes/"

  def privacy_policy
    data = WebInfo.where(name: "PRIVACY_POLICY").take
    render status: 200, json: {success: true, info: "DATA_RETURNED",data: data.description}
  end

  def terms_of_service
    data = WebInfo.where(name: "TERMS_OF_SERVICE").take
    render status: 200, json: {success: true, info: "DATA_RETURNED",data: data.description}
  end

  def tips
    tips = TipRecipe.all.order(updated_at: :desc)
      .paginate(page: params[:page], per_page: 15)

    data = Array.new
    tips.each do |tip|
      file_path = @@base_file_path + tip.description_render_path.sub(@@replaceable_path, @@replaceable_path+"_")
      description = File.open(file_path, "r"){|file| file.read }
      # description = ActionController::Base.helpers.strip_tags(description) # get rid of html tags

      data << { id: tip.id, title: tip.title, image: { url: tip.image.url, thumb: tip.image.url(:thumb) },
        description: description, video: tip.video, created_at: tip.created_at, updated_at: tip.updated_at}
    end

    render status: 200, json: {success: true, info: "DATA_RETURNED", data: data, per_page: 15}
  end

  def contact
    suggestion = Suggestion.new(suggestion_params)

    if suggestion.save
      render status: 200, json: {success: true, info: "SAVED"}
    else
      render status: 200, json: {success: false, info: "SAVE_ERROR"}
    end
  end

  def ecart_info
    warehouse = @current_user.City.State.Warehouse

    notice = WebInfo.where(name: "ECART_NOTICE").take
    description_file = @@base_file_path + notice.description_render_path.sub("/shared/web/", "/shared/web/_")
    description = File.open(description_file, "r"){|file| file.read }

    data = {shipping_cost: warehouse.shipping_cost, wholesale: warehouse.wholesale, ecart_notice: description}
    render status: 200, json: {success: true, info: "DATA_RETURNED", data: data}
  end

  private
  def suggestion_params
    {name: params[:name], email: params[:email].strip, message: params[:message]}
  end

end
