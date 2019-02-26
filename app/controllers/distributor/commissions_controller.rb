class Distributor::CommissionsController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_distributor?
  layout "distributor_layout.html.erb"

  def index
    @commissions = @current_user.Commissions.order(created_at: :desc)
                    .limit(100).paginate(page: params[:page], per_page: 25)
  end

  def details
    commission = @current_user.Commissions.find_by!(hash_id: params[:id])
    if commission.nil?
      flash[:info] = "No se encontró la comisión con clave: #{params[:id]}"
      redirect_to distributor_commissions_path
      return
    end

    order_ids = commission.Details.map { |m| m.order_id  }
    @orders = Order.where("id in (?)", order_ids).includes(:Client)
  end

  def upload_invoice
    commission = @current_user.Commissions.find_by!(hash_id: params[:id])
    if commission.nil?
      flash[:info] = "No se encontró la comisión con clave: #{params[:id]}"
      redirect_to distributor_commissions_path
      return
    end

    if commission.update_attributes(invoice: params[:commission][:invoice], state: "PAID_&_INVOICE")
      flash[:success] = "Factura cargada exitosamente."
    else
      flash[:info] = "Ocurrió un error al guardar la factura, recuerda que debes subirla en un archivo compreso rar o zip incluyendo el pdf y xml."
    end

    redirect_to distributor_commissions_path
  end

  def download_payment
    commission = @current_user.Commissions.find_by!(hash_id: params[:id])

    render_404 and return unless commission.payment_pdf.present? or commission.payment_img.present?

    file_path = commission.payment_pdf.path if commission.payment_pdf.present?
    file_path = commission.payment_img.path if commission.payment_img.present?

    send_file file_path
  end

  def download_invoice
    commission = @current_user.Commissions.find_by!(hash_id: params[:id])
    send_file commission.invoice.path
  end
end
