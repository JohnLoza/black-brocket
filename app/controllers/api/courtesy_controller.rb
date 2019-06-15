class Api::CourtesyController < ApiController

  def available
    order = Order.find_by!(hash_id: params[:id])
    # the order is not valid if it's not local one or has already been used
    if order.state != 'PICKED_UP' or order.courtesy_folio.present?
      render status: 200, json: { success: false, info: 'INVALID_ORDER' }
    else 
      render status: 200, json: { success: true, info: 'VALID_ORDER'}
    end
  end

  def update
    order = Order.find_by!(hash_id: params[:id])

    if order.state != 'PICKED_UP' or order.courtesy_folio.present?
      render status: 200, json: { success: false, info: 'INVALID_ORDER' }
      return
    end

    if order.update_attributes(courtesy_folio: params[:courtesy_folio])
      render status: 200, json: { success: true, info: "SAVED" }
    else
      errors = order.errors.full_messages
      render status: 200, json: { success: true, info: "NOT_SAVED", errors: errors }
    end
  end
end
