class Api::FiscalDataController < ApplicationController
  def show
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    current_user = Client.find_by(authentication_token: params[:authentication_token])
    if @current_user.blank?
      api_authentication_failed
      return
    end

    fiscal_data = @current_user.FiscalData

    if !fiscal_data.blank?
      render :status => 200,
             :json => { :success => true, :info => "DATA_RETURNED", data: fiscal_data,
                        state: fiscal_data.City.State.id, city: fiscal_data.City.id }
    else
      render :status => 200,
             :json => { :success => false, :info => "FISCAL_DATA_NOT_FOUND" }
    end
  end

  def create
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    current_user = Client.find_by(authentication_token: params[:authentication_token])
    if @current_user.blank?
      api_authentication_failed
      return
    end

    @fiscal_data = FiscalData.new(fiscal_params)
    @fiscal_data.city_id = params[:city_id]
    @fiscal_data.client_id = @current_user.id
    @fiscal_data.alph_key = random_alph_key(12).upcase

    if @fiscal_data.save
      render :status => 200,
             :json => { :success => true, :info => "SAVED" }
    else
      render :status => 200,
             :json => { :success => false, :info => "SAVE_ERROR" }
    end
  end

  def update
    if params[:authentication_token].blank?
      api_authentication_failed
      return
    end

    current_user = Client.find_by(authentication_token: params[:authentication_token])
    if @current_user.blank?
      api_authentication_failed
      return
    end

    @fiscal_data = @current_user.FiscalData
    @fiscal_data.city_id = params[:city_id]
    @fiscal_data.lastname = params[:fiscal_data][:lastname]==""
    @fiscal_data.mother_lastname = params[:fiscal_data][:mother_lastname]==""

    if @fiscal_data.update_attributes(fiscal_params)
      render :status => 200,
             :json => { :success => true, :info => "SAVED" }
    else
      render :status => 200,
             :json => { :success => false, :info => "SAVE_ERROR" }
    end
  end

  private
  def fiscal_params
    params.require(:fiscal_data).permit(
        :name, :lastname, :mother_lastname, :rfc,
        :street, :intnumber, :extnumber, :col, :cp)
  end
end
