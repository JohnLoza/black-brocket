class Api::LocationsController < ApplicationController
  def states
    states = State.all.order(:name)
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
      data << {id: city.id, name: city.name, lada: city.LADA}
    end

    render :status => 200,
           :json => { :success => true, :info => "CITIES_DATA",
                      :data => data }
  end
end
