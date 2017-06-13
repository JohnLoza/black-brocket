class Admin::StatisticsController < ApplicationController
  before_action :logged_in?
  before_action :current_user_is_a_worker?
  layout "admin_layout.html.erb"

  @@category = "STATISTICS"
  @@noProcessableOrders = ["PAYMENT_REJECTED","WAITING_FOR_PAYMENT","PAYMENT_DEPOSITED","ORDER_CANCELED"]

  def index
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    if params[:type] and params[:type]=="sales"
      @products = Product.select("id, name").where(deleted: :false)
      @distributors = Distributor.select("id, username").where(deleted: :false)
    end
  end

  def sales
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)
    # params[:products].sort! { |x,y| x.to_i <=> y.to_i } if params[:products]

    # get the orders details given the parameters the user entered #
    @details = getStatisticDetails(params[:from_date], params[:to_date], params[:products], params[:distributors])

    if @details
      # @chartDataSets Array with the data to be displayed by Chart.js #
      @chartDataSets = Array.new

      # fetch the products #
      if params[:products] and params[:products].any?
        @products = Product.select(:id, :alph_key, :name).where(deleted: false, id: params[:products]).order(id: :ASC)
      else
        @products = Product.select(:id, :alph_key, :name).where(deleted: false).order(id: :ASC)
      end

      # fetch the distributors #
      if params[:distributors] and params[:distributors].any?
        @distributors = Distributor.select(:id, :alph_key, :username).where(deleted: false, id: params[:distributors]).order(id: :ASC)
      else
        @distributors = Array.new
      end

      @chartDataSets = buildChartDataSet(@products, @distributors, @details)

    end # if @details
  end

  def best_distributors
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    selection = "sum(order_details.quantity) as sum_q, orders.distributor_id as dist_id, distributors.username as dist_username"

    @details = OrderDetail.select(selection).joins(Order: :Distributor)
                  .where.not(orders: {:state => @@noProcessableOrders})
                  .group("dist_id").order("sum_q desc").limit(params[:dist_quantity])

    @dist_names = @details.map{|detail| detail.dist_username}.to_json
  end

  def best_clients
    authorization_result = @current_user.is_authorized?(@@category, nil)
    return if !process_authorization_result(authorization_result)

    selection = "sum(order_details.quantity) as sum_q, orders.client_id as client_id, clients.username as client_username"

    @details = OrderDetail.select(selection).joins(Order: :Client)
                  .where.not(orders: {:state => @@noProcessableOrders})
                  .group("client_id").order("sum_q desc").limit(params[:client_quantity])

    @client_names = @details.map{|detail| detail.client_username}.to_json
  end

  private
  def getStatisticDetails(from_date, to_date, products, distributors)
    selection = "order_details.product_id, sum(order_details.quantity) as sum_q"
    where_cond = ""
    group_cond = "order_details.product_id"
    details = Array.new

    # build the sentence with the given parameters #
    if ((from_date != "" and to_date != "") or products or distributors)
      if from_date != "" and to_date != ""
        # add condition to search the orders between those two dates #
        where_cond += " DATE(order_details.created_at) BETWEEN '" + from_date + "' AND '" + to_date + "' "
      end
      if products and products.any?
        # add condition to search the orders with the specified products #
        where_cond += " AND " if where_cond != ""
        where_cond += " order_details.product_id IN ("+ products.map(&:inspect).join(', ') +") "
      end
      if distributors and distributors.any?
        # add condition to search the orders from the specified distributors #
        selection += ", orders.distributor_id as dist_id"
        group_cond = "dist_id, order_details.product_id"
        where_cond += " AND " if where_cond != ""
        where_cond += " orders.distributor_id IN ("+ distributors.map(&:inspect).join(', ') +") "
      end

      # search #
      details = OrderDetail.select(selection).joins(:Order)
          .where(where_cond).group(group_cond).order(product_id: :asc)
    else # no parameters given #
      # searching all the orders of all the products from the beginning of time #
      details = OrderDetail.select(selection).group(group_cond).order(product_id: :asc)
    end

    return details
  end # getStatisticDetails #

  def buildChartDataSet(products, distributors, details)
    chartDataSets = Array.new

    if distributors.any?
      indx = 0
      distributors.each do |distributor|
        # will hold the quantities of products sold #
        data = Hash.new

        products.each do |product|
          data[product.id] = 0
        end

        details.each do |detail|
          if detail.dist_id == distributor.id
            data[detail.product_id] = detail.sum_q
          end
        end

        chartDataSets << {
          label: distributor.username,
          backgroundColor: getBgColors[indx],
          hoverBackgroundColor: getHoverBgColors[indx],
          borderWidth: 1,
          data: data.values
        }
        indx += 1
      end # @distributors.each do #
    else
      # there are no distributors #
      data = Hash.new

      products.each do |product|
        data[product.id] = 0
      end

      details.each do |detail|
        data[detail.product_id] = detail.sum_q
      end

      chartDataSets << {
        label: "Todas las ventas",
        backgroundColor: getBgColors[0],
        hoverBackgroundColor: getHoverBgColors[0],
        borderWidth: 1,
        data: data.values
      }
    end


    return chartDataSets
  end # buildChartDataSet #

  def getBgColors
     colors = ["rgba(0, 150, 136, 0.5)", # teal
      "rgba(244, 67, 54, 0.5)", # red
      "rgba(63, 81, 181, 0.5)", # indigo
      "rgba(255, 193, 7, 0.5)", # amber
      "rgba(121, 85, 72, 0.5)", # brown
      "rgba(103, 58, 183, 0.5)", # deep purple
      "rgba(255, 152, 0, 0.5)", # orange
      "rgba(139, 195, 74, 0.5)"] # green
    return colors
  end # getBgColors

  def getHoverBgColors
    colors = ["rgba(0, 150, 136, 0.8)", # teal
      "rgba(244, 67, 54, 0.8)", # red
      "rgba(63, 81, 181, 0.8)", # indigo
      "rgba(255, 193, 7, 0.8)", # amber
      "rgba(121, 85, 72, 0.8)", # brown
      "rgba(103, 58, 183, 0.8)", # deep purple
      "rgba(255, 152, 0, 0.8)", # orange
      "rgba(139, 195, 74, 0.8)"] # green
    return colors
  end # getHoverBgColors

end
