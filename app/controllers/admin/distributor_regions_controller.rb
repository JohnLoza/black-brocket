class Admin::DistributorRegionsController < AdminController

  def index
    deny_access! and return unless @current_user.has_permission?('distributors@update_distribution_regions')

    @distributor = Distributor.find_by!(hash_id: params[:dist_id])

    @regions = @distributor.Regions
    @state = @distributor.City.State
    @cities = City.where(state_id: @state.id, distributor_id: nil)
  end

  def create
    deny_access! and return unless @current_user.has_permission?('distributors@update_distribution_regions')

    @saved = false
    @city = City.find_by!(id: params[:city_id])

    if @city.distributor_id == nil
      @city.update_attribute(:distributor_id, params[:distributor_region][:distributor_id])
      @saved = true
    end

    respond_to do |format|
      format.js { render :create, :layout => false }
    end
  end

  def destroy
    deny_access! and return unless @current_user.has_permission?('distributors@update_distribution_regions')

    @deleted = false
    @city = City.find_by!(id: params[:id])

    distributor = Distributor.find_by!(hash_id: params[:dist_id])

    if @city.distributor_id == distributor.id
      @city.update_attribute(:distributor_id, nil)
      @deleted = true
    end # if @city.distributor_id == distributor.id #

    respond_to do |format|
      format.js { render :destroy, :layout => false }
    end
  end

end
