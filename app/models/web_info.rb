class WebInfo < ApplicationRecord
  attr_accessor :body
  validates :description_render_path, presence: true
end
