class ApiController < ActionController::API
  include ApplicationHelper

  rescue_from ActiveRecord::RecordNotFound do |e|
    render_404
  end

  rescue_from ActionController::UnknownFormat do |e|
    render_404
  end

  rescue_from ActionController::UnknownController do |e|
    render_404
  end

  def authenticate_user!(model)
    render_authentication_error and return unless model.present?
    render_authentication_error and return unless params[:authentication_token].present?

    @current_user = model.find_by(authentication_token: params[:authentication_token])
    render_authentication_error and return unless @current_user

    if model == SiteWorker
      deny_access! and return unless @current_user.has_permission?("orders@capture_batches")
    end
  end

  def render_authentication_error
    render status: 401, json: { success: false, info: "AUTHENTICATION_ERROR" }
  end

  def deny_access!
    render status: 200, json: { success: false, info: "ACCESS_DENIED" }
  end

  def render_404
    # render status: 200, json: { success: false, info: "NOT_FOUND" }
    head :not_found
  end

  def search_params
    return nil unless params[:class]
    params[:class][:search]
  end
end
