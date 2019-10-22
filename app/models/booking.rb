class Booking < ApplicationRecord
  belongs_to :house
  belongs_to :room
  belongs_to :room_unit
  belongs_to :user

  after_initialize :init
  after_create :block_connected_rooms, if: Proc.new {|booking|  booking.status == 'confirmed'}

  private
  def init
    self.status  ||= :confirmed
  end

  def block_connected_rooms
    connected_rooms = []
    connected_rooms << self.room_unit.part_of_room
    connected_rooms += self.room_unit.consist_of_rooms

    connected_rooms.compact.each do |connected_room|
      Booking.find_or_initialize_by(dtstart: self.dtstart, dtend: self.dtstart, house: self.house, room: connected_room.room, room_unit: connected_room)
          .update(user: self.user, status: :blocked)
    end

  end
end
