class RoomUnit < ApplicationRecord
  belongs_to :house
  belongs_to :room
  belongs_to :part_of_room, class_name: 'RoomUnit', optional: true

  has_many :consist_of_rooms, class_name: 'RoomUnit', foreign_key: :part_of_room_id
  has_many :bookings
end
