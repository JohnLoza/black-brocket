class Admin::CommissionsController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_worker?
  layout "admin_layout.html.erb"

  @@category = "COMMISSIONS"

  # Commission states #
  # WAITING_FOR_PAYMENT #
  # PAYMENT_DEPOSITED #
  # PAID_&_INVOICE #

  def index
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    if params[:distributor]
      distributor = Distributor.find_by(hash_id: params[:distributor])
      if distributor.nil?
        flash[:info] = "No se encontró el distribuidor con clave #{params[:distributor]}"
        redirect_to admin_distributors_path
        return
      end

      @commissions = distributor.Commissions.order(created_at: :desc)
                        .limit(100).paginate(page: params[:page], per_page: 25)
                        .includes(:Distributor)
    else
      @commissions = Commission.all.order(created_at: :desc)
                        .limit(100).paginate(page: params[:page], per_page: 25)
                        .includes(:Distributor)
    end # if params[:distributor] #
  end

  def create
    authorization_result = @current_user.is_authorized?(@@category, "CREATE")
    return if !process_authorization_result(authorization_result)

    @distributor = Distributor.find_by(hash_id: params[:distributor])
    @orders = Order.where("hash_id in (?)", params[:order_keys]).where(commission_in_progress: false)
    # verify if we found any order corresponding to the given params #
    if !@orders.any?
      flash[:warning] = "No se encontraron las órdenes especificadas"
      redirect_to admin_orders_path(distributor: @distributor.hash_id, type: "DELIVERED")
      return
    end
    # verify that the distributor exists and he(she) has a commission value settled #
    if @distributor.nil? or @distributor.commission.nil?
      flash[:warning] = "El distribuidor no tiene definido su porcentaje de comisión"
      redirect_to admin_orders_path(distributor: @distributor.hash_id, type: "DELIVERED")
      return
    end

    total = 0
    @orders.each do |o|
      total += o.total
    end
    total = (total * @distributor.commission) / 100

    saved = false
    ActiveRecord::Base.transaction do
      commission = Commission.new()
      commission.hash_id = random_hash_id(12).upcase
      commission.distributor_id = @distributor.id
      commission.worker_id = @current_user.id
      commission.state = "WAITING_FOR_PAYMENT"
      commission.total = total
      commission.save

      @orders.update_all(commission_in_progress: true)
      @orders.each do |o|
        CommissionDetail.create(commission_id: commission.id, order_id: o.id)
      end
      saved = true
    end

    flash[:success] = "Comisión creada!" if saved
    flash[:danger] = "Ocurrió un error al guardar la información" if !saved
    redirect_to admin_orders_path(distributor: @distributor.hash_id, type: "DELIVERED")
  end

  def details
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    commission = Commission.find_by(hash_id: params[:id])
    if commission.nil?
      flash[:info] = "No se encontró la comisión con clave: #{params[:id]}"
      redirect_to admin_commissions_path
      return
    end

    order_ids = commission.Details.map { |m| m.order_id  }
    @orders = Order.where("id in (?)", order_ids).includes(:Client)
    @distributor = commission.Distributor
  end

  def upload_payment
    authorization_result = @current_user.is_authorized?(@@category, "PAY")
    return if !process_authorization_result(authorization_result)

    commission = Commission.find_by(hash_id: params[:id])
    if commission.nil?
      flash[:warning] = "No se encontró la comisión especificada"
      redirect_to admin_commissions_path
      return
    end

    if params[:commission][:payment].content_type == "application/pdf"
      attributes = {payment_pdf: params[:commission][:payment], payment_img: nil}
    else
      attributes = {payment_img: params[:commission][:payment], payment_pdf: nil}
    end
    attributes[:state] = "PAYMENT_DEPOSITED"
    attributes[:payment_day] = Time.now.to_formatted_s(:db)
    saved = true if commission.update_attributes(attributes)

    flash[:success] = "Pago cargado exitosamente." if saved
    flash[:danger] = "Ocurrió un error al guardar el pago, recuerda que los formatos admitidos son: jpg, jpeg, png y pdf" if !saved
    redirect_to admin_commissions_path
  end

  def download_invoice
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    commission = Commission.find_by(hash_id: params[:id])
    if commission.nil?
      flash[:warning] = "No se encontró la comisión especificada"
      redirect_to admin_commissions_path
      return
    end

    commission.update_attribute(:invoice_downloaded, true)
    send_file commission.invoice.path
  end

end
