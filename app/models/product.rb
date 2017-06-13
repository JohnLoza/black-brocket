class Product < ActiveRecord::Base
  attr_accessor :description_body, :preparation_body

  has_many :Questions, :class_name => 'ProdQuestion', :foreign_key => 'product_id'
  has_many :Recipes
  has_many :SubCategories, :class_name => 'ProdSubCategory', :foreign_key => 'product_id'
  has_many :OrderDetails
  has_many :Photos, :class_name => 'ProdPhoto', :foreign_key => 'product_id'

  validates :name, :price, presence: true

  validates :price, numericality: {greater_than_or_equal_to: :recommended_price}
  validates :recommended_price, numericality: {greater_than_or_equal_to: :lowest_price}
  validates :lowest_price, numericality: {less_than_or_equal_to: :recommended_price}

  mount_uploader :video, VideoUploader

  # When have search params
  def self.search(search, params_page)
    page = params_page
    page = 1 if !page

    if search.at(",") == ","
      search=search.gsub(/\s+/, "")
      search=search.gsub(',','|')
      operator = "REGEXP"
    else
      search = "%"+search+"%"
      operator = "LIKE"
    end

    where("(name #{operator} :search or alph_key #{operator} :search) and deleted=false", search: search)
        .order(created_at: :DESC).paginate(:page =>  page, :per_page => 20)
  end

  def self.show_admin(params_page)
    page = params_page
    page = 1 if !page

    where(deleted: false).order(created_at: :DESC).paginate(:page =>  page, :per_page => 20)
  end
end
