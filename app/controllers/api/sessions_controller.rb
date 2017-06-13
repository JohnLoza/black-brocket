class Api::SessionsController < ApplicationController

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
      user = Client.where(email: params[:email], deleted: false).take if user.blank?
    end

    if !user.blank?
      user_type = "CLIENT" if user_type == nil
    end

    if user.blank? or !user.authenticate(params[:password])
      api_authentication_failed
      return
    end

    user.update_attribute(:authentication_token, SecureRandom.urlsafe_base64(16))
    render :status => 200,
           :json => { :success => true, :info => "AUTHORIZED",
                      :data => { :auth_token => user.authentication_token, :user_type => user_type} }
  end

  def destroy
    user = SiteWorker.find_by(authentication_token: params[:authentication_token])
    user = Distributor.find_by(authentication_token: params[:authentication_token])
    user = Client.find_by(authentication_token: params[:authentication_token])

    if user.blank?
      api_authentication_failed
      return
    end

    user.update_attribute(:authentication_token, nil)
    render :status => 200,
           :json => { :success => true, :info => "LOGGED_OUT" }
  end
end
