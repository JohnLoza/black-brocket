class Api::FiscalDataController < ApiController
  before_action do
    authenticate_user!(Client)
  end

  def show
    fiscal_data = @current_user.FiscalData

    if !fiscal_data.blank?
      render status: 200,
        json: {success: true, info: "DATA_RETURNED", data: fiscal_data,
          state: fiscal_data.City.State.id, city: fiscal_data.City.id }
    else
      render status: 200, json: {success: false, info: "FISCAL_DATA_NOT_FOUND"}
    end
  end

  def create
    @fiscal_data = FiscalData.new(fiscal_params)
    @fiscal_data.city_id = params[:city_id]
    @fiscal_data.client_id = @current_user.id
    @fiscal_data.hash_id = Utils.new_alphanumeric_token(9).upcase

    if @fiscal_data.save
      render status: 200, json: {success: true, info: "SAVED"}
    else
      render status: 200, json: {success: false, info: "SAVE_ERROR"}
    end
  end

  def update
    @fiscal_data = @current_user.FiscalData
    @fiscal_data.city_id = params[:city_id]

    if @fiscal_data.update_attributes(fiscal_params)
      render status: 200, json: {success: true, info: "SAVED"}
    else
      render status: 200, json: {success: false, info: "SAVE_ERROR"}
    end
  end

  private
  def fiscal_params
    params.require(:fiscal_data).permit(:name, :rfc, :street, :intnumber, :extnumber, :col, :cp)
  end
end
