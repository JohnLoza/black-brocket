class Client::FiscalDataController < ApplicationController
  before_action -> { user_should_be(Client) }

  def new
    @fiscal_data = FiscalData.new
    @states = State.order_by_name
    @cities = Array.new
    @url = client_fiscal_data_path
  end

  def edit
    @fiscal_data = @current_user.FiscalData
    redirect_to new_client_fiscal_datum_path and return unless @fiscal_data

    city = @fiscal_data.City
    params[:city_id] = city.id
    params[:state_id] = city.state_id

    @states = State.order_by_name
    @cities = City.where(state_id: params[:state_id]).order_by_name
    @url = client_fiscal_datum_path @fiscal_data
  end

  def create
    @fiscal_data = FiscalData.new(fiscal_params)
    @fiscal_data.city_id = params[:city_id]
    @fiscal_data.client_id = @current_user.id

    @fiscal_data.save!
    redirect_to products_path, flash: {success: "Información fiscal guardada"}
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
    @states = State.order_by_name
    @cities = City.where(state_id: params[:state_id]).order_by_name
    @url = client_fiscal_data_path
    render :new
  end

  def update
    @fiscal_data = @current_user.FiscalData
    @fiscal_data.city_id = params[:city_id]

    @fiscal_data.update_attributes!(fiscal_params)
    redirect_to products_path, flash: {success: "Información fiscal guardada"}
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
    @states = State.order_by_name
    @cities = City.where(state_id: params[:state_id]).order_by_name
    @url = client_fiscal_datum_path @fiscal_data
    render :edit
  end

  private
    def fiscal_params
      params.require(:fiscal_data).permit(
          :name, :lastname, :mother_lastname, :rfc,
          :street, :intnumber, :extnumber, :col, :cp)
    end
end
