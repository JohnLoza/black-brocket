class Admin::CommissionsController < AdminController
  # Commission states #
  # WAITING_FOR_PAYMENT #
  # PAYMENT_DEPOSITED #
  # PAID_&_INVOICE #

  def index
    deny_access! and return unless @current_user.has_permission_category?("commissions")

    if params[:distributor]
      distributor = Distributor.find_by!(hash_id: params[:distributor])
      distributor_id = distributor.id
    end

    @commissions = Commission.order(created_at: :desc).by_distributor(distributor_id)
      .search(key_words: search_params, fields: ["hash_id", "state"])
      .paginate(page: params[:page], per_page: 25).includes(:Distributor)
  end

  def create
    deny_access! and return unless @current_user.has_permission?("commissions@create")
    unless params[:order_keys].present?
      flash[:info] = "Seleccione las órdenes que componen la comisión."
      redirect_to admin_orders_path(distributor: params[:distributor], type: "DELIVERED")
      return
    end

    distributor = Distributor.find_by!(hash_id: params[:distributor])
    orders = Order.where(hash_id: params[:order_keys]).where(commission_in_progress: false)
    raise ActiveRecord::RecordNotFound unless orders.any?

    total = Commission.calculateCommission(orders, distributor.commission)

    commission = Commission.new({hash_id: Utils.new_alphanumeric_token(9).upcase,
      distributor_id: distributor.id, worker_id: @current_user.id,
      state: "WAITING_FOR_PAYMENT", total: total })
    ActiveRecord::Base.transaction do
      commission.save!
      orders.update_all(commission_in_progress: true)
      orders.each do |o|
        CommissionDetail.create(commission_id: commission.id, order_id: o.id)
      end
      flash[:success] = "Comisión creada!"
    end

    flash[:info] = "Ocurrió un error al guardar la información" unless flash[:success].present?
    redirect_to admin_orders_path(distributor: distributor.hash_id, type: "DELIVERED")
  end

  def details
    deny_access! and return unless @current_user.has_permission_category?("commissions")

    commission = Commission.find_by!(hash_id: params[:id])

    order_ids = commission.Details.map { |m| m.order_id  }
    @orders = Order.where("id in (?)", order_ids).includes(:Client)
    @distributor = commission.Distributor
  end

  def upload_payment
    deny_access! and return unless @current_user.has_permission?("commissions@pay")

    commission = Commission.find_by!(hash_id: params[:id])

    commission.payment = params[:commission][:payment]
    commission.state = "PAYMENT_DEPOSITED"
    commission.payment_day = Time.now.to_formatted_s(:db)
    flash[:success] = "Pago cargado exitosamente." if commission.save

    flash[:info] = "Ocurrió un error al guardar el pago, recuerda que los formatos admitidos son: jpg, jpeg, png y pdf" unless flash[:success].present?
    redirect_to admin_commissions_path
  end

  def download_payment
    deny_access! and return unless @current_user.has_permission_category?("commissions")
    commission = Commission.find_by!(hash_id: params[:id])
    render_404 and return unless commission.payment.present?

    send_file commission.payment.path
  end

  def download_invoice
    deny_access! and return unless @current_user.has_permission_category?("commissions")

    commission = Commission.find_by!(hash_id: params[:id])

    commission.update_attribute(:invoice_downloaded, true)
    send_file commission.invoice.path
  end

end
