class Admin::BanksController < AdminController

  def index
    unless @current_user.has_permission_category?("banks") or
           @current_user.has_permission_category?("bank_accounts")
      deny_access! and return
    end
    @banks = Bank.search(key_words: search_params, fields: ["name"])
  end

  def new
    deny_access! and return unless @current_user.has_permission?("banks@create")

    @bank = Bank.new
  end

  def create
    deny_access! and return unless @current_user.has_permission?("banks@create")

    @bank = Bank.new(bank_params)

    if @bank.save
      flash[:success] = "El banco se guardo exitosamente"
      redirect_to admin_banks_path
    else
      @url = admin_banks_path
      render :new
    end
  end

  def edit
    deny_access! and return unless @current_user.has_permission?("banks@update")

    @bank = Bank.find(params[:id])
  end

  def update
    deny_access! and return unless @current_user.has_permission?("banks@update")

    @bank = Bank.find(params[:id])

    if @bank.update_attributes(bank_params)
      flash[:success] = "Registro del banco actualizado!"
      redirect_to admin_banks_path
    else
      render :edit
    end
  end

  def destroy
    deny_access! and return unless @current_user.has_permission?("banks@delete")

    @bank = Bank.find(params[:id])

    if @bank.destroy
      flash[:success] = "Registro de banco eliminado definitivamente"
    else
      flash[:info] = "Ocurrió un error al eliminar el registro, inténtalo de nuevo por favor"
    end # @bank_account and @bank_account.destroy #

    redirect_to admin_banks_path
  end

  private
    def bank_params
      params.require(:bank).permit(:name, :owner, :email, :RFC, :image)
    end
end
