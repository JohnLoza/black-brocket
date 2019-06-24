class Admin::BankReportsController < AdminController

  def index
    deny_access! unless @current_user.has_permission?("orders@accept_reject_payment")

    @report_history = BankReportView.all.order(created_at: :desc).limit(50).includes(:Worker)
  end

  # Not used
  def show
    deny_access! unless @current_user.has_permission?("orders@accept_reject_payment")

    BankReportView.create(worker_id: @current_user.id,
      from_date: params[:from_date], to_date: params[:to_date],
      details: "Visualizó todos los bancos" )

    @banks = Bank.all
    @orders = {}
    @banks.each do |bank|
      @orders[bank.id] = Order.where("DATE(created_at) BETWEEN :from AND :to",
        from: params[:from_date], to: params[:to_date]).where(payment_method: bank.id)
    end

    render :show, layout: false
  end

end
