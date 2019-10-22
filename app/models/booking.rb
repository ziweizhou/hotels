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
      unless Booking.where('room_unit_id = ? AND ((dtstart >= ? AND dtstart < ?) OR (dtend > ? AND dtend <= ?))',
                         connected_room.id, self.dtstart, self.dtend, self.dtstart, self.dtend).present?
        Booking.create(dtstart: self.dtstart, dtend: self.dtend, house: self.house, room: connected_room.room, room_unit: connected_room, user: self.user, status: :blocked)
      end
    end

  end
end
