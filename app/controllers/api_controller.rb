class ApiController < ActionController::API
  before_action :authenticate_user!

  @@user_type = :default

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

  def authenticate_user!
    render_authentication_error and return unless params[:authentication_token].present?

    case @@user_type
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

    if @@user_type == :site_worker
      deny_access! and return unless @current_user.has_permission?('orders@capture_batches')
    end
  end

  def render_authentication_error
    render :status => 401,
          :json => { :success => false,
                      :info => "AUTHENTICATION_ERROR" }
  end

  def deny_access!
    render :status => 200,
           :json => { :success => false, :info => "ACCESS_DENIED" }
  end

  def render_404
    head :not_found
  end

  def search_params
    return nil unless params[:class]
    params[:class][:search]
  end
end
