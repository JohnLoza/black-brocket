class Api::LocationsController < ApiController
  skip_before_action :authenticate_user!

  def states
    states = State.order_by_name
    data = Array.new
    states.each do |state|
      data << {id: state.id, name: state.name}
    end

    render :status => 200,
           :json => { :success => true, :info => "STATES_DATA",
                      :data => data }
  end

  def cities
    cities = City.where(state_id: params[:id]).order(:name)
    data = Array.new
    cities.each do |city|
      data << {id: city.id, name: city.name, lada: city.lada}
    end

    render :status => 200,
           :json => { :success => true, :info => "CITIES_DATA",
                      :data => data }
  end
end
