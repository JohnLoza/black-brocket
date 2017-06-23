class Client::ClientsController < ApplicationController
  before_action :logged_in?, except:  [ :new, :create ]
  before_action :current_user_is_a_client?, except:  [ :new, :create ]

  def distributor
    if params[:notification]
      notification = Notification.find(params[:notification])
      notification.update_attribute(:seen, true)
    end

    @distributor = @current_user.City.Distributor
    if !@distributor and !@current_user.worker_id.blank?
      @worker = @current_user.Worker
    end

    if @distributor or @worker
      @messages = @current_user.DistributorMessages.all.order(:created_at => :desc)
                    .paginate(page: params[:page], :per_page => 25)
      @create_message_url = client_create_distributor_comment_path(@distributor.id) if @distributor
      @create_message_url = client_create_distributor_comment_path(@worker.id) if @worker

      @client_image = User.getImage(@current_user, :mini)
      @client_username = @current_user.username
      if @distributor
        @distributor_image = User.getImage(@distributor, :mini)
        @distributor_username = @distributor.username
      end
      if @worker
        @distributor_image = User.getImage(@worker, :mini)
        @distributor_username = @worker.username
      end
    end
  end

  def notifications
    @notifications = @current_user.Notifications.order(created_at: :desc)
                      .limit(50).paginate(page: params[:page], per_page: 15)
  end

  def pre_destroy_account

  end

  def destroy_account
    if !@current_user.authenticate(params[:password])
      flash[:warning]="Contraseña incorrecta."
      redirect_to client_destroy_account_path(@current_user.alph_key)
      return
    end
    @current_user.deleted=true
    @current_user.delete_account_hash= SecureRandom.urlsafe_base64(6)

    if @current_user.save
      log_out
      session.delete(:e_cart)
    end
    redirect_to good_bye_path(params[:id])
  end

  def prod_answer
    if params[:notification]
      notification = Notification.find(params[:notification])
      notification.update_attribute(:seen, true)
    end

    @question = ProdQuestion.find(params[:id])
    @answer = @question.Answer
  end

  def new
    @client = Client.new
    @states = State.all.order(:name)
    @cities = Array.new
    @url = client_clients_path
  end

  def create
    @client = Client.new(client_params)
    @client.city_id = params[:city_id]

    @city_id = params[:city_id]
    @state_id = params[:state_id]

    if @client.save
      @client.update_attribute(:alph_key, generateAlphKey("C", @client.id))

      log_in(@client, 'c')
      flash[:success] = "Bienvenido a Black Brocket, por ser su primera compra y para brindarle un mejor servicio, nuestro distribuidor de zona se pondrá en contacto o un representante de ventas se comunicará con usted. Si es una Pyme, dueño de una cafetería, tiene negocio relacionado con alimentos o es mayorista le ofrecemos precios y descuentos preferenciales bastante atractivos. Estos se los dará nuestro  representante de ventas, así como una demostración de nuestros productos. Una vez hecho el pago de su pedido los descuentos no se bonifican. Puede contactarnos en el menú en la opción \“distribuidores en la zona\”."
      redirect_to products_path
    else
      @client.errors.each do |field, msg|
        puts "--- #{field} #{msg} ---"
      end

      @url = client_clients_path

      @states = State.all.order(:name)
      @cities = City.where(state_id: @state_id)

      flash.now[:danger] = 'Ocurrió un error al guardar los datos, inténtalo de nuevo por favor.'
      render :new
    end
  end

  def edit
    @client = current_user
    client_city = @client.City
    @city_id = client_city.id
    @state_id = client_city.state_id

    @states = State.all.order(:name)
    @cities = City.where(state_id: @state_id)
    @url = client_client_path(@current_user.alph_key)
  end

  def update
    @client = current_user
    @client.city_id = params[:city_id]

    # address_changed = false;
    # if @client.street != params[:client][:street] or @client.col != params[:client][:col] or @client.extnumber != params[:client][:extnumber]
    #   address_changed = true
    # end

    if @client.update_attributes(client_params)
      flash[:success] = "Tu información ha sido actualizada!"
      redirect_to products_path
      return
    else
      flash.now[:danger] = 'Ocurrió un error al guardar los datos, inténtalo de nuevo por favor.'
      @url = client_client_path(params[:id])

      @city_id = params[:city_id]
      @state_id = params[:state_id]

      @states = State.all.order(:name)
      @cities = City.where(state_id: @state_id)
      render :edit
    end
  end

  def update_distributor_visit
    @visit = DistributorVisit.find(params[:id])
    @visit.update_attributes(visit_params)

    flash[:success] = "Gracias por tu participación."
    redirect_to products_path
  end

  def create_distributor_comment
    @distributor = @current_user.City.Distributor
    if !@distributor and !@current_user.worker_id.blank?
      @worker = @current_user.Worker
    end

    message = ClientDistributorComment.new(message_params)

    if @distributor
      message.distributor_id = @distributor.id
      notification = Notification.create(distributor_id: @distributor.id, icon: "fa fa-comments-o",
                      description: "El usuario " + @current_user.username + " te envió un mensaje",
                      url: distributor_client_messages_path(@current_user.alph_key))
    elsif @worker
      message.worker_id = @worker.id
      Notification.create(worker_id: @worker.id, icon: "fa fa-comments-o",
                      description: "El usuario " + @current_user.username + " te envió un mensaje",
                      url: admin_distributor_work_client_messages_path(@current_user.alph_key))
    end

    message.save
    flash[:success] = "Mensaje guardado."
    redirect_to client_my_distributor_path
  end

  private
    def client_params
      params.require(:client).permit(:username, :email, :email_confirmation, :rfc,
                                     :street, :col, :intnumber, :extnumber,
                                     :cp, :street_ref1, :street_ref2, :telephone,
                                     :password, :password_confirmation, :birthday,
                                     :fiscal_number, :photo, :cellphone,
                                     :name, :lastname, :mother_lastname)
    end

    def visit_params
      params.require(:distributor_visit).permit(:client_recognizes_visit,
                                         :treatment_answer, :extra_comments)
    end

    def message_params
      {client_id: @current_user.id, comment: params[:comment],
      is_from_client: true}
    end

    def generate_bank_reference(city_id, alph_key)
      city = City.find(city_id)
      states = State.all.order(name: :asc)

      cont = 1
      state = nil
      state_ref = nil

      states.each do |s|
        if s.id == city.state_id
          state = s
          if cont < 10
            state_ref = "0"+cont.to_s
          else
            state_ref = cont.to_s
          end
        else
          cont += 1
        end
      end

      country = Country.find(state.country_id)
      country_ref = country.name.at(0)

      return country_ref + state_ref + alph_key.sub("-","0")
    end

end
