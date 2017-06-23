class Admin::BankAccountsController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_worker?
  layout "admin_layout.html.erb"

  @@category = "BANK_ACCOUNTS"

  def index
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    @bank_accounts = BankAccount.all

    # determine the actions the user can do, so we can display them in screen #
    @actions = {"SHOW"=>false,"CREATE"=>false,"DELETE"=>false,"UPDATE"=>false}
    if !@current_user.is_admin
      @user_permissions.each do |p|
        # see if the permission category is equal to the one we need in these controller #
        if p.category == @@category
          @actions[p.name]=true
        end # if p.category == @@category #
      end # @user_permissions.each end #
    else
      @actions = {"SHOW"=>true,"CREATE"=>true,"DELETE"=>true,"UPDATE"=>true}
    end # if !@current_user.is_admin end #
  end # def index #

  def new
    authorization_result = @current_user.is_authorized?(@@category, "CREATE")
    return if !process_authorization_result(authorization_result)

    _new()
    @bank_account = BankAccount.new
  end # def new #

  def create
    authorization_result = @current_user.is_authorized?(@@category, "CREATE")
    return if !process_authorization_result(authorization_result)

    @bank_account = BankAccount.new(bank_account_params)

    if @bank_account.save
      flash[:success] = "Creación de cuenta exitosa"
      redirect_to admin_bank_accounts_path
      return
    else
      _new()
      render :new
      return
    end
  end # def create #

  def show
    authorization_result = @current_user.is_authorized?(@@category, "SHOW")
    return if !process_authorization_result(authorization_result)
  end # def show #

  def edit
    authorization_result = @current_user.is_authorized?(@@category, "UPDATE")
    return if !process_authorization_result(authorization_result)

    _edit()
    @bank_account = BankAccount.find_by(id: params[:id])
    if @bank_account.nil?
      flash[:info] = "No se encontró la cuenta bancaria con clave: #{params[:id]}"
      redirect_to admin_bank_accounts_path
      return
    end
  end # def edit #

  def update
    authorization_result = @current_user.is_authorized?(@@category, "UPDATE")
    return if !process_authorization_result(authorization_result)

    @bank_account = BankAccount.find_by(id: params[:id])
    if @bank_account.nil?
      flash[:info] = "No se encontró la cuenta bancaria con clave: #{params[:id]}"
      redirect_to admin_bank_accounts_path
      return
    end

    if @bank_account.update_attributes(bank_account_params)
      flash[:success] = "Actualización exitosa"
      redirect_to admin_bank_accounts_path
      return
    else # if else @bank_account.update_attributes(bank_account_params) #
      _edit()
      render :new
      return
    end # if @bank_account.update_attributes(bank_account_params) #
  end # def update #

  def destroy
    authorization_result = @current_user.is_authorized?(@@category, "DELETE")
    return if !process_authorization_result(authorization_result)

    @bank_account = BankAccount.find_by(params[:id])
    if @bank_account.nil?
      flash[:info] = "No se encontró la cuenta bancaria con clave: #{params[:id]}"
      redirect_to admin_bank_accounts_path
      return
    end
    
    if @bank_account and @bank_account.destroy
      flash[:success] = "Cuenta de banco eliminada definitivamente"
    else
      flash[:danger] = "Ocurrió un error al eliminar la cuenta, inténtalo de nuevo por favor"
    end # @bank_account and @bank_account.destroy #

    redirect_to admin_bank_accounts_path
  end # def destroy #

  private
    def bank_account_params
      params.require(:bank_account).permit(:bank_name, :account_number, :owner,
      :RFC, :interbank_clabe, :email)
    end # def bank_account_params #

    def _new
      @url = admin_bank_accounts_path
    end # def _new #

    def _edit
      @url = admin_bank_account_path(params[:id])
    end # def _edit #
end # class #
