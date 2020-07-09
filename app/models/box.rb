class Box
  @@FILE_PATH = "config/black_brocket/boxes.json"

  def self.all()
    JSON.parse File.read(@@FILE_PATH)
  end

  def self.setBoxes(json)
    # order from bigger to smaller using weight as reference
    json.sort!{|a, b| b[:weight] <=> a[:weight]}

    File.write(@@FILE_PATH, json.to_json)
  end

  def self.order_by(dimension, direction)
    boxes = self.all()
    dimension = dimension.to_s

    if direction == :desc
      boxes.sort{|a, b| b[dimension] <=> a[dimension]}
    else
      boxes.sort{|a, b| a[dimension] <=> b[dimension]}
    end
  end

  def self.selectByWeight(cart_weight)
    boxes = self.order_by(:weight, :desc) # bigger boxes first
    boxes_selected = Hash.new
    remaining_cart_weight = cart_weight.to_f / 1000

    while remaining_cart_weight > 0 # keep adding boxes til there is no product left
      boxes.each do |box|
        use_this_box = false
        if remaining_cart_weight >= box["weight"] or # if box is used fully
          (remaining_cart_weight * 100 / box["weight"]).between?(90, 100) # or between 70 to 99 percent

          no_boxes = (remaining_cart_weight / box["weight"]).floor
          no_boxes = 1 if no_boxes == 0 # change no_boxes to 1 when box is almost full

          if boxes_selected[box["name"]].present?
            boxes_selected[box["name"]] += no_boxes
          else
            boxes_selected[box["name"]] = no_boxes
          end

          remaining_cart_weight -= no_boxes * box["weight"]
          use_this_box = true
        end # end if
        break if use_this_box
      end # end boxes.each

      # use the smallest box for the last resort
      if remaining_cart_weight > 0 and remaining_cart_weight < boxes.last["weight"]
        if boxes_selected[boxes.last["name"]].present?
          boxes_selected[boxes.last["name"]] += 1
        else
          boxes_selected[boxes.last["name"]] = 1
        end
        remaining_cart_weight -= boxes.last["weight"]
      end # end if
    end # end while

    return boxes_selected, boxes
  end

  def self.fetchSrQuotations(zc, box)
    # production API KEY = SQoaP1oPC0bXuUVIrzaARitVruXXRrVOEDiOYUUi6Q4t
    # demo API KEY = PhrFxG93iBFSQpDwmTuYGeESANNpJjNTF91l6Hf3AXQt
    weight = box["weight"] + (box["box_weight"]/1000)
    weight = weight.round(3)

    res = `curl \"https://api.skydropx.com/v1/quotations\" \\
      -H \"Authorization: Token token=SQoaP1oPC0bXuUVIrzaARitVruXXRrVOEDiOYUUi6Q4t\" \\
      -H \"Content-Type: application/json\" --request POST \\
      --data '{\"zip_from\":\"44100\",\"zip_to\":\"#{zc}\",\"parcel\":{\"weight\":#{weight},\"height\":#{box["height"]},\"width\":#{box["width"]},\"length\":#{box["length"]}}}'`

    quotations = JSON.parse res
    # quotations = quotations.select do |hash|
    #   case hash["provider"]
    #   when "SENDEX", "CARSSA", "REDPACK", "ESTAFETA", "QUIKEN", "PAQUETEXPRESS"
    #     false
    #   else
    #     true
    #   end
    # end

    return quotations
  end
end
