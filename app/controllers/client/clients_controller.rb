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
    unless @current_user.authenticate(params[:password])
      flash[:info] = "Contraseña incorrecta."
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
    params[:no_loader] = true
  end

  def create
    @client = Client.new(client_params)
    @client.city_id = params[:city_id]
    @client.save!
    @client.update_attribute(:hash_id, generateAlphKey("C", @client.id))
    SendConfirmationEmailJob.perform_later(@client)

    log_in(@client, "c")
    flash[:success] = "Bienvenido a Black Brocket, por ser su primera compra 
      y para brindarle un mejor servicio, nuestro distribuidor de zona se 
      pondrá en contacto o un representante de ventas se comunicará con usted.
      Si es una Pyme, dueño de una cafetería, tiene negocio relacionado 
      con alimentos o es mayorista le ofrecemos precios y descuentos 
      preferenciales bastante atractivos. Estos se los dará nuestro 
      representante de ventas, así como una demostración de nuestros productos.
      Una vez hecho el pago de su pedido los descuentos no se bonifican. 
      Puede contactarnos en el menú en la opción \“distribuidores en la zona\”."
    redirect_to products_path
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved 
    @states = State.order_by_name
    @cities = City.where(state_id: params[:state_id])
    render :new
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
    @client.update_attributes!(client_params)
    redirect_to products_path, flash: {success: "Perfil guardado"}
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved 
    @states = State.order_by_name
    @cities = City.where(state_id: params[:state_id]).order_by_name
    flash.now[:info] = "Ocurrió un error al guardar." and render :edit
  end

  def update_distributor_visit
    visit = DistributorVisit.find(params[:id])
    visit.update_attributes(visit_params)
    @current_user.set_last_visit(visit)

    redirect_to products_path, flash: {success: "Gracias por tu participación."}
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
    @distributor = @current_user.Worker if @current_user.worker_id
    @distributor ||= @current_user.City.Distributor
    @message = ClientDistributorComment.new(message_params(@distributor))

    notificate_new_message(@distributor)
    SendMessageNotificationJob.perform_later(user: @distributor, sender: @current_user, message: params[:comment])

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

    def message_params(distributor)
      message_params = {client_id: @current_user.id, comment: params[:comment], is_from_client: true}

      case distributor.class.to_s
      when "Distributor"
        message_params[:distributor_id] = distributor.id
      when "SiteWorker"
        message_params[:worker_id] = distributor.id
      end

      return message_params
    end

    def notificate_new_message(user)
      n = Notification.new(description: "#{@current_user.name} te envió un mensaje", icon: "fa fa-comments-o")

      case user.class.to_s
      when "SiteWorker"
        n.worker_id = user.id
        n.url = admin_distributor_work_client_messages_path(@current_user)
      when "Distributor"
        n.distributor_id = user.id
        n.url = distributor_client_messages_path(@current_user)
      end # case user.class.to_s
      n.save
    end
end
