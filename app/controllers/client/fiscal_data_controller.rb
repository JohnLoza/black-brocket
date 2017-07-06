class Client::FiscalDataController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_client?

  def new
    @fiscal_data = FiscalData.new
    @states = State.all.order(:name)
    @cities = Array.new
    @url = client_fiscal_data_path
  end

  def edit
    @fiscal_data = @current_user.FiscalData
    if !@fiscal_data
      redirect_to new_client_fiscal_datum_path
      return
    end

    city = @fiscal_data.City
    @city_id = city.id
    @state_id = city.state_id

    @states = State.all.order(:name)
    @cities = City.where(state_id: @state_id)
    @url = client_fiscal_datum_path
  end

  def create
    @fiscal_data = FiscalData.new(fiscal_params)
    @fiscal_data.city_id = params[:city_id]
    @fiscal_data.client_id = @current_user.id
    @fiscal_data.alph_key = SecureRandom.urlsafe_base64(6)

    if @fiscal_data.save
      flash[:success] = "Información fiscal guardada."
      redirect_to client_ecart_path(@current_user.alph_key)
      return
    else
      @state_id = params[:state_id]
      @city_id = params[:city_id]

      @states = State.all.order(:name)
      @cities = City.where(state_id: @state_id).order(:name)
      @url = client_fiscal_data_path
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
      redirect_to products_path(@current_user.alph_key)
    else
      city = @fiscal_data.City
      @city_id = city.id
      @state_id = city.state_id

      @states = State.all.order(:name)
      @cities = City.where(state_id: @state_id)
      @url = client_fiscal_datum_path
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
