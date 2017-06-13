class Admin::DistributorRegionsController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_worker?
  layout "admin_layout.html.erb"

  @@category = "DISTRIBUTORS"
  @@permission_name = "UPDATE_DISTRIBUTION_REGIONS"

  def index
    authorization_result = @current_user.is_authorized?(@@category, @@permission_name)
    return if !process_authorization_result(authorization_result)

    @distributor = Distributor.find_by(alph_key: params[:dist_id])
    if @distributor.nil?
      flash[:info] = "No se encontró el distribuidor con clave #{params[:dist_id]}"
      redirect_to admin_distributors_path
      return
    end

    @distributor_city = @distributor.City
    @regions = @distributor.Regions

    @state = @distributor.City.State
    @cities = City.where(state_id: @state.id, distributor_id: nil)
  end

  def create
    authorization_result = @current_user.is_authorized?(@@category, @@permission_name)
    return if !process_authorization_result(authorization_result)

    @saved = false
    @city = City.find_by(id: params[:city_id])
    if !@city.nil?

      if @city.distributor_id == nil
        puts "--- the city is free to be taken, updating it ---"
        @city.update_attribute(:distributor_id, params[:distributor_region][:distributor_id])
        @saved = true
      end

    end # if @city.nil? #

    respond_to do |format|
      format.js { render :create, :layout => false }
    end
  end

  def destroy
    authorization_result = @current_user.is_authorized?(@@category, @@permission_name)
    return if !process_authorization_result(authorization_result)

    @deleted = false
    @city = City.find_by(id: params[:id])

    if !@city.nil?
      distributor = Distributor.find_by(alph_key: params[:dist_id])

      if !distributor.nil?

        if @city.distributor_id == distributor.id
          @city.update_attribute(:distributor_id, nil)
          @deleted = true
        end # if @city.distributor_id == distributor.id #

      else
        puts "--- Distributor with key #{params[:dist_id]} not found ---"
      end # if distributor.nil? #

    else
      puts "--- City with key #{params[:id]} not found ---"
    end # if @city.nil? #

    respond_to do |format|
      format.js { render :destroy, :layout => false }
    end
  end

end
