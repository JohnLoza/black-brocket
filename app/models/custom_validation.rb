class CustomValidation
  def self.validateOrderShipment(order_details, shipment_details)
    order_details.each do |order_detail|
      product_captured = false

      # iterate through the shipment details to verify the product quantities are the ones the client wanted #
      shipment_details.each do |shipment_detail|
        if order_detail.product_id == shipment_detail.product_id
          if order_detail.quantity != shipment_detail.t_quantity
            return {success: false, error_message: "La cantidad de productos a enviar no es correcta."}
          else
            product_captured = true
          end
        end
      end

      # if a product hasn't been captured stop the execution #
      return {success: false, error_message: "No se esta surtiendo el pedido completo."} unless product_captured
    end

    return {success: true}
  end
end
