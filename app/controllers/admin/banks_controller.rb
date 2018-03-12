class Admin::BanksController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_worker?
  layout "admin_layout.html.erb"

  @@category = "BANK_ACCOUNTS"

  def index
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @banks = Bank.all

    # determine the actions the user can do, so we can display them in screen #
    @actions = {"SHOW"=>false,"CREATE"=>false,"DELETE"=>false,"UPDATE"=>false}
    if !@current_user.is_admin
      @user_permissions.each do |p|
        # see if the permission category is equal to the one we need in these controller #
        if p.category == @@category
          @actions[p.name]=true
        end # if p.category == @@category #d
      end # @user_permissions.each end #
    else
      @actions = {"SHOW"=>true,"CREATE"=>true,"DELETE"=>true,"UPDATE"=>true}
    end # if !@current_user.is_admin end #
  end

  def new
    authorization_result = @current_user.is_authorized?(@@category, "CREATE")
    return if !process_authorization_result(authorization_result)

    @url = admin_banks_path
    @bank = Bank.new
  end

  def edit
    authorization_result = @current_user.is_authorized?(@@category, "UPDATE")
    return if !process_authorization_result(authorization_result)

    @bank = Bank.find_by(id: params[:id])
    if !@bank
      flash[:info] = "No se encontró el banco especificado"
      redirect_to admin_banks_path
      return
    end

    @url = admin_bank_path(@bank.id)
  end

  def create
    authorization_result = @current_user.is_authorized?(@@category, "CREATE")
    return if !process_authorization_result(authorization_result)

    @bank = Bank.new(bank_params)

    if @bank.save
      flash[:success] = "El banco se guardo exitosamente"
      redirect_to admin_banks_path
      return
    else
      @url = admin_banks_path
      render :new
      return
    end
  end

  def update
    authorization_result = @current_user.is_authorized?(@@category, "UPDATE")
    return if !process_authorization_result(authorization_result)

    @bank = Bank.find_by(id: params[:id])
    if !@bank
      flash[:info] = "No se encontró el banco especificado"
      redirect_to admin_banks_path
      return
    end

    if @bank.update_attributes(bank_params)
      flash[:success] = "Registro del banco actualizado!"
      redirect_to admin_banks_path
    else
      @url = admin_bank_path(@bank.id)
      render :edit
    end
  end

  def destroy
    authorization_result = @current_user.is_authorized?(@@category, "DELETE")
    return if !process_authorization_result(authorization_result)

    @bank = Bank.find_by(params[:id])
    if @bank.nil?
      flash[:info] = "No se encontró el banco especificado"
      redirect_to admin_bank_accounts_path
      return
    end

    if @bank.destroy
      flash[:success] = "Registro de banco eliminado definitivamente"
    else
      flash[:danger] = "Ocurrió un error al eliminar el registro, inténtalo de nuevo por favor"
    end # @bank_account and @bank_account.destroy #

    redirect_to admin_bank_accounts_path
  end

  private
    def bank_params
      params.require(:bank).permit(:name, :owner, :email, :RFC, :image)
    end
end
