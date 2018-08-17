class Api::DistributorApi::CommissionsController < ApiController
  @@user_type = :distributor

  def index
    commissions = @current_user.Commissions.order(created_at: :desc)
                    .limit(100).paginate(page: params[:page], per_page: 25)
    data = Array.new
    data<<{per_page: 25}
    commissions.each do |commission|
      data << {hash_id: commission.hash_id, total: commission.total,
        status: I18n.t(commission.state), date: I18n.l(commission.created_at, format: :long),
        payment_img: commission.payment_img.url, payment_pdf: commission.payment_pdf.url}
    end

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }
  end

  def show
    commission = @current_user.Commissions.find_by!(hash_id: params[:id])

    order_ids = commission.Details.map { |m| m.order_id  }
    orders = Order.where(id: order_ids).includes(:Client)
    data = Array.new
    orders.each do |order|
      data << {hash_id: order.hash_id, total: order.total, client_username: order.Client.username,
        client_hash_id: order.Client.hash_id, status: I18n.t(order.state), payment_img: commission.payment_img.url, payment_pdf: commission.payment_pdf.url}
    end

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }
  end
end
