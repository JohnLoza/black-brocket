module SessionsHelper
  # Logs in the given user.
  def log_in(user, user_type)
    session[:user_id] = user.id
    session[:user_type] = user_type
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
    if session[:user_id].present?
      user_id = session[:user_id]
      user_type = session[:user_type]
      @current_user ||= find_user_by_type(user_type, user_id)
    elsif cookies.signed[:user_id].present?
      user_id = cookies.signed[:user_id]
      user_type = cookies[:user_type]
      user = find_user_by_type(user_type, user_id)

      if user and user.authenticated?(:remember, cookies[:remember_token])
        log_in(user, user_type)
        @current_user = user
      else
        forget(user)
      end # if user and user.authenticated?
    end # if session[:user_id] / elsif 
  end

  # Returns true if the user is logged in, false otherwise.
  def logged_in?
    !current_user.nil?
  end

  # Forgets a persistent session.
  def forget(user)
    user.forget if user
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
    return true
  end

  # Stores the URL trying to be accessed.
  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end

  # Check wheter the user is a Client, SiteWorker or Distributor
  def user_should_be(type)
    unless logged_in?
      store_location
      redirect_to log_in_path and return
    end

    return true if current_user.class == type
    redirect_to root_path and return
  end

  private
    def find_user_by_type(user_type, user_id)
      case user_type
      when "w"
        SiteWorker.find_by(id: user_id)
      when "d"
        Distributor.find_by(id: user_id)
      when "c"
        Client.find_by(id: user_id)
      else
        return nil
      end
    end
end
