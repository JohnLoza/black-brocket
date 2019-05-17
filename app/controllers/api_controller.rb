class ApiController < ActionController::API
  # rescue_from Exception, with: :method not working somehow
  rescue_from ActiveRecord::RecordNotFound do |e|
    render_404
  end
  rescue_from ActionController::UnknownFormat do |e|
    render_404
  end
  rescue_from ActionController::UnknownController do |e|
    render_404
  end
  rescue_from ActionController::RoutingError do |e|
    render_404
  end

  def authenticate_user!(type)
    render_authentication_error and return unless type.present?
    render_authentication_error and return unless params[:authentication_token].present?

    case type
    when :site_worker
      model = SiteWorker
    when :distributor
      model = Distributor
    when :client
      model = Client
    else
      render_404 and return
    end

    @current_user = model.find_by(authentication_token: params[:authentication_token])
    render_authentication_error and return unless @current_user.present?

    if type == :site_worker
      deny_access! and return unless @current_user.has_permission?('orders@capture_batches')
    end
  end

  def render_authentication_error
    render status: 401, json: {success: false, info: "AUTHENTICATION_ERROR"}
  end

  def deny_access!
    render status: 200, json: {success: false, info: "ACCESS_DENIED"}
  end

  def render_404
    head :not_found
  end

  def search_params
    return nil unless params[:class]
    params[:class][:search]
  end

  def random_hash_id(number)
    hash_id = Array.new
    index = 0
    while index < number
      i = SecureRandom.random_number(alphanumericArray.size)
      hash_id << alphanumericArray[i]
      index += 1
    end
    return hash_id.join
  end

  def alphanumericArray
    ['q','w','e','r','t','y','u','p','a','s','d','f','g','h','j','k','z',
      'x','c','v','b','n','m','1','2','3','4','5','6','7','8','9','0']
  end
end
