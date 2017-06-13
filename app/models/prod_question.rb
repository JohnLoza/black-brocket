class ProdQuestion < ActiveRecord::Base
  belongs_to :Product, :foreign_key => :product_id
  belongs_to :Client, :foreign_key => :client_id

  has_one :Answer, :class_name => 'ProdAnswer', :foreign_key => :question_id

  validates :product_id, :client_id, presence: true,
                                   numericality: { only_integer: true }
  validates :description, presence: true
end
