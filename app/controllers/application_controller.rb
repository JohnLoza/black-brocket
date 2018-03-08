class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include ApplicationHelper
  include SessionsHelper

  # before_action :set_locale

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

  def render_404
    respond_to do |format|
      format.html { render file: Rails.root.join("public", "404"), layout: false, status: 404 }
      format.any { head :not_found }
    end
  end

  # def set_locale
  #   I18n.locale = params[:locale] || I18n.default_locale
  #   Time.zone = 'Guadalajara'
  # end

end
