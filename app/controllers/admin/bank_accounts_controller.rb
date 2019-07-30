class Admin::BankAccountsController < AdminController

  def index
    deny_access! and return unless @current_user.has_permission_category?("bank_accounts")

    @bank = Bank.find_by!(id: params[:bank_id])
    @bank_accounts = @bank.Accounts.search(key_words: search_params, fields: ["account_number", "interbank_clabe"])
  end # def index #

  def new
    deny_access! and return unless @current_user.has_permission?("bank_accounts@create")

    @bank = Bank.find_by!(id: params[:bank_id])
    @bank_account = BankAccount.new
  end # def new #

  def create
    deny_access! and return unless @current_user.has_permission?("bank_accounts@create")

    @bank = Bank.find_by!(id: params[:bank_id])

    @bank_account = BankAccount.new(bank_account_params)
    @bank_account.email = @bank.email
    @bank.Accounts << @bank_account

    if @bank.save
      flash[:success] = "Creación de cuenta exitosa"
      redirect_to admin_bank_accounts_path(@bank)
    else
      render :new
    end
  end # def create #

  def edit
    deny_access! and return unless @current_user.has_permission?("bank_accounts@update")

    @bank = Bank.find_by!(id: params[:bank_id])
    @bank_account = @bank.Accounts.find_by!(id: params[:id])
  end # def edit #

  def update
    deny_access! and return unless @current_user.has_permission?("bank_accounts@update")

    @bank = Bank.find_by!(id: params[:bank_id])
    @bank_account = @bank.Accounts.find_by!(id: params[:id])

    if @bank_account.update_attributes(bank_account_params)
      flash[:success] = "Cuenta guardada"
      redirect_to admin_bank_accounts_path
    else
      render :edit
    end
  end # def update #

  def destroy
    deny_access! and return unless @current_user.has_permission?("bank_accounts@delete")

    @bank = Bank.find_by!(id: params[:bank_id])
    @bank_account = @bank.Accounts.find_by!(id: params[:id])

    if @bank_account.destroy
      flash[:success] = "Cuenta de banco eliminada definitivamente"
    else
      flash[:info] = "Ocurrió un error al eliminar la cuenta, inténtalo de nuevo por favor"
    end # @bank_account.destroy #

    redirect_to admin_bank_accounts_path
  end # def destroy #

  private
    def bank_account_params
      params.require(:bank_account).permit(:bank_name, :account_number, :owner,
      :RFC, :interbank_clabe)
    end # def bank_account_params #
end # class #
