class Api::WorkersApi::DistributorsController < ApiController
  @@user_type = :site_worker

  def show
    order = Order.find_by!(hash_id: params[:id])
    distributor = order.Distributor

    unless distributor
      render :status => 200,
             :json => { :success => false, :info => "DISTRIBUTOR_NOT_FOUND" }
    end

    data = Hash.new
    city = distributor.City


    data = {address: "", city: city.name, state: city.State.name, username: distributor.username, name: distributor.name,
            lastname: distributor.lastname, mother_lastname: distributor.mother_lastname,
            email: distributor.email, telephone: distributor.telephone, cellphone: distributor.cellphone,
            photo: distributor.avatar_url}

    if distributor.show_address
      data[:address] = distributor.address
    end

    render :status => 200,
           :json => { :success => true, :info => "DATA_RETURNED", :data => data }
  end

end
