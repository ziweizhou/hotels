class Booking < ApplicationRecord
  belongs_to :house
  belongs_to :room
  belongs_to :user
end
