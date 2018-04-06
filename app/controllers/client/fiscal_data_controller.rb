class Client::FiscalDataController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_client?

  def new
    @fiscal_data = FiscalData.new
    @states = State.order_by_name
    @cities = Array.new
  end

  def edit
    @fiscal_data = @current_user.FiscalData
    redirect_to new_client_fiscal_datum_path and return unless @fiscal_data

    city = @fiscal_data.City
    params[:city_id] = city.id
    params[:state_id] = city.state_id

    @states = State.order_by_name
    @cities = City.where(state_id: params[:state_id]).order_by_name
  end

  def create
    @fiscal_data = FiscalData.new(fiscal_params)
    @fiscal_data.city_id = params[:city_id]
    @fiscal_data.client_id = @current_user.id
    @fiscal_data.hash_id = random_hash_id(12).upcase

    if @fiscal_data.save
      flash[:success] = "Información fiscal guardada."
      redirect_to client_ecart_path(@current_user.hash_id)
    else
      params[:state_id] = params[:state_id]
      params[:city_id] = params[:city_id]

      @states = State.order_by_name
      @cities = City.where(state_id: params[:state_id]).order_by_name
      render :new
    end
  end

  def update
    @fiscal_data = @current_user.FiscalData
    @fiscal_data.city_id = params[:city_id]
    @fiscal_data.lastname = params[:fiscal_data][:lastname]==""
    @fiscal_data.mother_lastname = params[:fiscal_data][:mother_lastname]==""

    if @fiscal_data.update_attributes(fiscal_params)
      flash[:success] = "Información fiscal guardada."
      redirect_to products_path(@current_user.hash_id)
    else
      city = @fiscal_data.City
      params[:city_id] = city.id
      params[:state_id] = city.state_id

      @states = State.order_by_name
      @cities = City.where(state_id: params[:state_id]).order_by_name
      render :edit
    end
  end

  private
    def fiscal_params
      params.require(:fiscal_data).permit(
          :name, :lastname, :mother_lastname, :rfc,
          :street, :intnumber, :extnumber, :col, :cp)
    end
end
