class Api::CourtesyController < ApiController

  def available
    order = Order.find_by!(hash_id: params[:id])
    # the order is not valid if it's not local one or has already been used
    if order.state == 'PICKED_UP' and order.courtesy_folio.nil?
      render status: 200, json: { success: true, info: 'VALID_ORDER'}
    elsif order.courtesy_folio.present?
      render status: 200, json: { success: false, info: 'COURTESY_FOLIO_PRESENT'}
    else 
      render status: 200, json: { success: false, info: 'INVALID_ORDER' }
    end
  end

  def update
    order = Order.find_by!(hash_id: params[:id])

    if order.state != 'PICKED_UP' or order.courtesy_folio.present?
      render status: 200, json: { success: false, info: 'INVALID_ORDER' } and return
    end

    if order.update_attributes(courtesy_folio: params[:courtesy_folio])
      render status: 200, json: { success: true, info: "SAVED" }
    else
      errors = order.errors.full_messages
      render status: 200, json: { success: true, info: "NOT_SAVED", errors: errors }
    end
  end
end
