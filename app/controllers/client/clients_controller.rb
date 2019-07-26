class Client::ClientsController < ApplicationController
  before_action except: [ :new, :create, :email_confirmation ] do
    user_should_be(Client)
  end
  before_action :process_notification, only: [:prod_answer, :distributor]
  layout "static_pages.html.erb", only: [ :new ]

  def notifications
    @notifications = @current_user.Notifications.order(created_at: :desc)
      .limit(50).paginate(page: params[:page], per_page: 15)
  end

  def pre_destroy_account

  end

  def destroy_account
    if !@current_user.authenticate(params[:password])
      flash[:warning] = "Contraseña incorrecta."
      redirect_to client_destroy_account_path(@current_user.hash_id) and return
    end

    if @current_user.destroy
      @current_user.update_attribute(:delete_account_hash, Utils.new_alphanumeric_token(9).upcase)
      session.delete(:e_cart); log_out
    end

    redirect_to good_bye_path(params[:id])
  end

  def prod_answer
    @question = ProdQuestion.find(params[:id])
    @answer = @question.Answer
  end

  def new
    redirect_to products_path and return if logged_in?

    @client = Client.new
    @states = State.order_by_name
    @cities = Array.new
  end

  def create
    @client = Client.new(client_params)
    @client.city_id = params[:city_id]

    if false and @client.save
      @client.update_attribute(:hash_id, generateAlphKey("C", @client.id))
      SendConfirmationEmailJob.perform_later(@client)

      log_in(@client, "c")
      flash[:success] = "Bienvenido a Black Brocket, por ser su primera compra y para brindarle un mejor servicio, nuestro distribuidor de zona se pondrá en contacto o un representante de ventas se comunicará con usted. Si es una Pyme, dueño de una cafetería, tiene negocio relacionado con alimentos o es mayorista le ofrecemos precios y descuentos preferenciales bastante atractivos. Estos se los dará nuestro  representante de ventas, así como una demostración de nuestros productos. Una vez hecho el pago de su pedido los descuentos no se bonifican. Puede contactarnos en el menú en la opción \“distribuidores en la zona\”."
      redirect_to products_path
    else
      @states = State.order_by_name
      @cities = City.where(state_id: params[:state_id])
      flash.now[:info] = "Ocurrió un error al guardar." and render :new
    end
  end

  def edit
    @client = @current_user
    client_city = @client.City
    params[:city_id] = client_city.id
    params[:state_id] = client_city.state_id
    params[:lada] = client_city.lada

    @states = State.order_by_name
    @cities = City.where(state_id: params[:state_id]).order_by_name
  end

  def update
    @client = @current_user
    @client.city_id = params[:city_id]

    if @client.update_attributes(client_params)
      flash[:success] = "Tu información ha sido guardada!"
      redirect_to products_path and return
    else
      @states = State.order_by_name
      @cities = City.where(state_id: params[:state_id]).order_by_name
      flash.now[:danger] = "Ocurrió un error al guardar." and render :edit
    end
  end

  def update_distributor_visit
    visit = DistributorVisit.find(params[:id])
    visit.update_attributes(visit_params)

    if visit.client_recognizes_visit
      @current_user.update_attribute(:last_distributor_visit, visit.visit_date)
    end

    flash[:success] = "Gracias por tu participación."
    redirect_to products_path
  end

  def distributor
    @distributor = @current_user.Worker if @current_user.worker_id
    @distributor ||= @current_user.City.Distributor

    return unless @distributor
    @messages = @distributor.ClientMessages.where(client_id: @current_user.id)
      .order(created_at: :desc).paginate(page: params[:page], per_page: 25)
    @create_message_url = client_create_distributor_comment_path(@distributor.id)

    @client_image = @current_user.avatar_url(:mini)
    @client_username = @current_user.name
    @distributor_image = @distributor.avatar_url(:mini)
    @distributor_username = @distributor.username
  end

  def create_distributor_comment
    @distributor = @current_user.City.Distributor
    if !@distributor and !@current_user.worker_id.blank?
      @worker = @current_user.Worker
    end

    @message = ClientDistributorComment.new(message_params)

    if @distributor
      @message.distributor_id = @distributor.id
      Notification.create(distributor_id: @distributor.id, icon: "fa fa-comments-o",
        description: "El usuario " + @current_user.name + " te envió un mensaje",
        url: distributor_client_messages_path(@current_user.hash_id))
    elsif @worker
      @message.worker_id = @worker.id
      Notification.create(worker_id: @worker.id, icon: "fa fa-comments-o",
        description: "El usuario " + @current_user.name + " te envió un mensaje",
        url: admin_distributor_work_client_messages_path(@current_user.hash_id))
    end

    @client_image = @current_user.avatar_url(:mini)
    @client_username = @current_user.name

    @message.save
    respond_to do |format|
      format.js { render :create_distributor_comment, layout: false }
    end
  end

  def email_confirmation
    @user = Client.find_by!(validate_email_digest: params[:token])
    @user.update_attributes(email_verified: true, validate_email_digest: nil)
  end

  def resend_email_confirmation
    SendConfirmationEmailJob.perform_later(@current_user)
    flash[:success] = "El correo electrónico ha sido enviado"
    redirect_to products_path
  end

  private
    def client_params
      params.require(:client)
        .permit(:username, :email, :email_confirmation, :rfc, :street, :col, 
          :intnumber, :extnumber, :password, :password_confirmation, :birthday,
          :cp, :street_ref1, :street_ref2, :telephone, :name, :lastname, 
          :mother_lastname, :fiscal_number, :photo, :cellphone)
    end

    def visit_params
      params.require(:distributor_visit).permit(:client_recognizes_visit, 
        :treatment_answer, :extra_comments)
    end

    def message_params
      {client_id: @current_user.id, comment: params[:comment], is_from_client: true}
    end
end
