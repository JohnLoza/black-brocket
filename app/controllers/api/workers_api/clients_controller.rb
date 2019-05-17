class Api::WorkersApi::ClientsController < ApiController
  before_action do
    authenticate_user!(:site_worker)
  end

  def show
    order = Order.find_by!(hash_id: params[:id])
    c = order.Client

    data = {username: c.username, email: c.email, street: c.street,
            colony: c.col, intnumber: c.intnumber, extnumber: c.extnumber,
            zipcode: c.cp, street_ref1: c.street_ref1, street_ref2: c.street_ref2,
            telephone: c.telephone, birthday: c.birthday, cellphone: c.cellphone,
            name: c.name, lastname: c.lastname, mother_lastname: c.mother_lastname,
            photo: c.avatar_url}

    render status: 200, json: {success: true, info: "DATA_RETURNED",
      data: data, city_name: c.City.name, state_name: c.City.State.name}
  end

end
