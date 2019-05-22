class Api::SessionsController < ApiController
  before_action except: :create do
    authenticate_user!(:client)
  end

  def create
    user_type = nil
    user = SiteWorker.find_by(email: params[:email])

    if !user.blank?
      user_type = "WORKER" if user_type == nil
    else
      user = Distributor.find_by(email: params[:email])
    end

    if !user.blank?
      user_type = "DISTRIBUTOR" if user_type == nil
    else
      user = Client.find_by(email: params[:email], deleted_at: nil)
    end

    if !user.blank?
      user_type = "CLIENT" if user_type == nil
    end

    if user.blank? or !user.authenticate(params[:password])
      render_authentication_error and return
    end

    unless user.authentication_token.present?
      user.update_attribute(:authentication_token, SecureRandom.urlsafe_base64(16))
    end

    render status: 200, json: {success: true, info: "AUTHORIZED",
      data: {auth_token: user.authentication_token, user_type: user_type}}
  end

  def destroy
    user = SiteWorker.find_by(authentication_token: params[:authentication_token])
    user = Distributor.find_by(authentication_token: params[:authentication_token]) unless user
    user = Client.find_by(authentication_token: params[:authentication_token]) unless user
    render_authentication_error and return unless user

    user.update_attribute(:authentication_token, nil)
    render status: 200, json: {success: true, info: "LOGGED_OUT"}
  end
end
