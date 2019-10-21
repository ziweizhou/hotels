class Booking < ApplicationRecord
  belongs_to :house
  belongs_to :room
  belongs_to :room_unit
  belongs_to :user
end
