class RoomUnit < ApplicationRecord
  belongs_to :house
  belongs_to :room
  belongs_to :unit
  
  has_many :bookings
end
