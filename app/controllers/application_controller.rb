class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }
  include ApplicationHelper
  include SessionsHelper

  before_action :set_locale
  before_filter :load_current_user

  def set_locale
    # base functionality
    # I18n.locale = params[:locale] || I18n.default_locale
    I18n.locale = :es
  end

  def load_current_user
    puts "--- loading current_user ---"
    @current_user = current_user
  end
end
