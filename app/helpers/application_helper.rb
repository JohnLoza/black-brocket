module ApplicationHelper
  def generateAlphKey(letter, number)
    if number <= 9
      new_key = "000"+(number).to_s
    elsif number >= 10 and number < 100
      new_key = "00"+(number).to_s
    elsif number >= 100 and number < 1000
      new_key = "0"+(number).to_s
    else
      new_key = (number).to_s
    end

    return letter + new_key
  end

  def process_authorization_result(authorization_result, redirect_to_admin_home_page = true)
    authorized = false

    if authorization_result.any?
      @links = authorization_result[0]
      @user_permissions = authorization_result[1]
      authorized = true
    elsif redirect_to_admin_home_page
      flash[:warning] = "No tienes permisos para acceder a la página solicitada"
      redirect_to admin_welcome_path
      return false
    else
      return authorized
    end
  end

  def date_format(date_string)
    month = ""

    case date_string.month
    when 1
      month = "Enero"
    when 2
      month = "Febrero"
    when 3
      month = "Marzo"
    when 4
      month = "Abril"
    when 5
      month = "Mayo"
    when 6
      month = "Junio"
    when 7
      month = "Julio"
    when 8
      month = "Agosto"
    when 9
      month = "Septiembre"
    when 10
      month = "Octubre"
    when 11
      month = "Noviembre"
    when 12
      month = "Diciembre"
    end

    new_string = date_string.day.to_s + " de " + month + " del " + date_string.year.to_s
    return new_string
  end

end
