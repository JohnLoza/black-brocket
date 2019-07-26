module ApplicationHelper
  def generateAlphKey(letter, number)
    if number <= 9
      new_key = "000#{number}"
    elsif number >= 10 and number < 100
      new_key = "00#{number}"
    elsif number >= 100 and number < 1000
      new_key = "0#{number}"
    else
      new_key = number.to_s
    end

    return letter + new_key
  end

  def process_notification
    if params[:notification].present?
      n = Notification.find(params[:notification])
      n.update_attribute(:seen, true) unless n.seen
    end
  end
end
