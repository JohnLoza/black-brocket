module SessionsHelper
  # Logs in the given user.
  def log_in(user, type)
    session[:user_id] = user.id
    session[:user_type] = type
  end # def log_in #

  # Remembers a user in a persistent session.
  def remember(user, type)
    user.remember_token = user.new_token
    user.update_attribute(:remember_digest, user.digest(user.remember_token))

    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
    cookies.permanent[:user_type] = type
  end # def remember #

  # Returns true if the given user is the current user.
  def current_user?(user)
    user == current_user
  end

  # Returns the current logged-in user (if any).
  def current_user
    if !session[:user_id].nil?
      user_id = session[:user_id]
      user_type = session[:user_type]

      if user_type == 'w'
        @current_user ||= SiteWorker.find_by!(id: user_id)
      elsif  user_type == 'd'
        @current_user ||= Distributor.find_by!(id: user_id)
      elsif  user_type == 'c'
        @current_user ||= Client.find_by!(id: user_id)
      end

    elsif !cookies.signed[:user_id].nil?
      user_id = cookies.signed[:user_id]
      user_type = cookies[:user_type]

      if user_type == 'w'
        user = SiteWorker.find_by!(id: user_id)
      elsif  user_type == 'd'
        user = Distributor.find_by!(id: user_id)
      elsif  user_type == 'c'
        user = Client.find_by!(id: user_id)
      end

      if user && user.authenticated?(:remember, cookies[:remember_token])
        log_in(user, user_type)
        @current_user = user
      end

    end
  end

  # Returns true if the user is logged in, false otherwise.
  def logged_in?
    !current_user.nil?
  end

  # Forgets a persistent session.
  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
    cookies.delete(:user_type)
  end

  # Logs out the current logged-in user
  def log_out
    if !current_user.nil?
      forget(current_user)

      session.delete(:user_id)
      session.delete(:user_type)
      @current_user = nil
    end
  end # def log_out #

  # Redirects to stored location (or to the default).
  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end

  # Stores the URL trying to be accessed.
  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end

  # See if the current user is a worker #
  def current_user_is_a_worker?
    if session[:user_type] != "w"
      redirect_to root_path
      return false
    else
      return true
    end
  end

  # See if the current user is a distributor #
  def current_user_is_a_distributor?
    if session[:user_type] != "d"
      redirect_to root_path
      return false
    else
      return true
    end
  end

  # See if the current user is a client #
  def current_user_is_a_client?
    if session[:user_type] != "c"
      redirect_to root_path
      return false
    else
      return true
    end
  end

  def api_authentication_failed
    render :status => 401,
          :json => { :success => false,
                      :info => "AUTHENTICATION_ERROR" }
  end

end
