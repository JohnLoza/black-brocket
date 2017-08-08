class Admin::BankReportsController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_worker?
  layout "admin_layout.html.erb"

  @@category = "ORDERS"

  def index
    authorization_result = @current_user.is_authorized?(@@category, "ACCEPT_REJECT_PAYMENT")
    return if !process_authorization_result(authorization_result)

    @report_history = BankReportView.all.order(created_at: :desc).limit(50)
                          .includes(:Worker)
  end

  # Not used
  def show
    authorization_result = @current_user.is_authorized?(@@category, "ACCEPT_REJECT_PAYMENT")
    return if !process_authorization_result(authorization_result)

    BankReportView.create(worker_id: @current_user.id,
      from_date: params[:from_date], to_date: params[:to_date],
      details: "Visualizó todos los bancos" )

    @banks = Bank.all
    @orders = {}
    @banks.each do |bank|
      @orders[bank.id] = Order.where("DATE(created_at) BETWEEN :from AND :to",
                          from: params[:from_date], to: params[:to_date])
                          .where(payment_method: bank.id)
    end

    render :show, layout: false
  end

end
