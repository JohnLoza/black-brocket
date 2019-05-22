class Admin::DistributorsController < AdminController
  skip_before_action :verify_authenticity_token, only: :answer_candidate

  def index
    deny_access! unless @current_user.has_permission_category?('distributors')

    @states = State.all.order(name: :ASC)
    @cities = Array.new

    @distributors = Distributor.active.order_by_name
      .by_region(city_id: params[:city_id], state_id: params[:state_id])
      .search(key_words: search_params, joins: {City: :State}, fields: fields_to_search)
      .paginate(page: params[:page], per_page: 20).includes(City: :State)
  end # def index end #

  def new
    deny_access! unless @current_user.has_permission?('distributors@create')

    @distributor = Distributor.new
    @states = State.order_by_name
    @cities = Array.new
  end

  def create
    deny_access! unless @current_user.has_permission?('distributors@create')

    @distributor = Distributor.new(distributor_params)
    @distributor.city_id = params[:city_id]

    if @distributor.save
      @distributor.update_attribute(:hash_id, generateAlphKey("D", @distributor.id))
      redirect_to admin_distributor_path(@distributor), flash: {success: 'Distribuidor guardado' }
    else
      @cities = City.where(state_id: params[:state_id]).order_by_name
      @states = State.order_by_name

      flash.now[:danger] = 'Ocurrió un error al guardar los datos, inténtalo de nuevo por favor.'
      render :new
    end
  end

  def show
    unless @current_user.has_permission?('distributors@show_personal_data') or
           @current_user.has_permission?('distributors@show_fiscal_data') or
           @current_user.has_permission?('distributors@show_bank_data') or
           @current_user.has_permission?('distributors@show_distribution_regions') or
           @current_user.has_permission?('distributors@show_commission')
      deny_access! and return
    end

    @distributor = Distributor.find_by!(hash_id: params[:id])
    @regions = @distributor.Regions
  end

  def edit
    unless @current_user.has_permission?('distributors@update_personal_data') or
           @current_user.has_permission?('distributors@update_fiscal_data') or
           @current_user.has_permission?('distributors@update_bank_data') or
           @current_user.has_permission?('distributors@update_show_address') or
           @current_user.has_permission?('distributors@update_commission') or
           @current_user.has_permission?('distributors@update_photo')
      deny_access! and return
    end

    @distributor = Distributor.find_by!(hash_id: params[:id])

    params[:city_id] = @distributor.city_id
    params[:state_id] = @distributor.City.state_id
    @cities = City.where(state_id: params[:state_id]).order_by_name
    @states = State.order_by_name
  end

  def update
    unless @current_user.has_permission?('distributors@update_personal_data') or
           @current_user.has_permission?('distributors@update_fiscal_data') or
           @current_user.has_permission?('distributors@update_bank_data') or
           @current_user.has_permission?('distributors@update_show_address') or
           @current_user.has_permission?('distributors@update_commission') or
           @current_user.has_permission?('distributors@update_photo')
      deny_access! and return
    end

    @distributor = Distributor.find_by!(hash_id: params[:id])
    @distributor.city_id = params[:city_id]

    if @distributor.update_attributes(distributor_params)
      redirect_to admin_distributors_path, flash: {success: 'El distribuidor se actualizó.' }
    else
      @cities = City.where(state_id: params[:state_id]).order_by_name
      @states = State.order_by_name

      flash.now[:danger] = 'Ocurrió un error al guardar los datos, inténtalo de nuevo por favor.'
      render :edit
    end
  end

  def destroy
    deny_access! and return unless @current_user.has_permission?('distributors@delete')

    @distributor = Distributor.find_by!(hash_id: params[:id])

    if @distributor.destroy
      @distributor.Regions.update_all(distributor_id: nil)
      flash[:success] = 'Distribuidor eliminado.'
    else
      flash[:info] = 'Ocurrió un error al eliminar el trabajador, inténtalo de nuevo por favor.'
    end
    redirect_to admin_distributors_path
  end

  def candidates
    deny_access! and return unless @current_user.has_permission?('distributors@requests')

    @candidates = DistributorCandidate.all.order(created_at: :desc)
                    .paginate(page: params[:page], per_page: 20).includes(:City)
  end

  def answer_candidate
    deny_access! and return unless @current_user.has_permission?('distributors@requests')
    candidate = DistributorCandidate.find(params[:id])
    if candidate
      SendAnswerToCandidateJob.perform_later(candidate, params[:answer])
      candidate.update_attribute(:read, true)
      flash[:success] = "Respuesta a #{candidate.getFullName} enviada!."
      redirect_to admin_distributor_candidates_path
    end
  end

  private
    def distributor_params
      params.require(:distributor).permit(:name, :username, :email, :rfc, 
        :address, :telephone, :password, :password_confirmation, :birthday,
        :fiscal_number, :lastname, :mother_lastname, :commission, :photo,
        :cellphone, :bank_name, :bank_account_owner, :bank_account_number,
        :interbank_clabe, :show_address)
    end

    def fields_to_search
      return ['cities.name','states.name','distributors.name',
        'distributors.lastname','distributors.mother_lastname',
        'distributors.hash_id', 'distributors.username']
    end

end
