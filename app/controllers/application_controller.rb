class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, only: [:render_404]

  include ApplicationHelper
  include SessionsHelper

  rescue_from ActiveRecord::RecordNotFound do |e|
    render_404
  end

  rescue_from ActionController::UnknownFormat do |e|
    render_404
  end
  
  rescue_from ActionController::UnknownController do |e|
    render_404
  end

  def render_404
    respond_to do |format|
      format.html { render file: Rails.root.join("public", "404"), layout: false, status: 404 }
      format.any { head :not_found }
    end
  end
end
