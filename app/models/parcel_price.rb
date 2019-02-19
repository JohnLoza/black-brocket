class ParcelPrice < ApplicationRecord
    before_save { self.max_weight = max_weight * 1000 }

    belongs_to :Parcel, foreign_key: :parcel_id

    validates :max_weight, presence: true, numericality: true
    validates :price, presence: true, numericality: { less_than: 999999.99 }
end
  