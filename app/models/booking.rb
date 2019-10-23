class Booking < ApplicationRecord
  belongs_to :house
  belongs_to :room
  belongs_to :room_unit
  belongs_to :user

  belongs_to :parent, class_name: 'Booking', optional: true
  has_many :children, class_name: 'Booking', foreign_key: :parent_booking_id

  after_initialize :init
  after_create :block_connected_rooms, if: Proc.new {|booking|  booking.status == 'confirmed' && booking.room_unit.virtual}
  after_destroy :destroy_connected_bookings

  private
  def init
    self.status  ||= :confirmed
  end

  def block_connected_rooms
    room_unit.consist_of_rooms.each do |connected_room|
      unless Booking.where('room_unit_id = ? AND ((dtstart >= ? AND dtstart < ?) OR (dtend > ? AND dtend <= ?))',
                         connected_room.id, self.dtstart, self.dtend, self.dtstart, self.dtend).present?
        Booking.create(dtstart: self.dtstart,
                       dtend: self.dtend,
                       house: self.house,
                       room: connected_room.room,
                       room_unit: connected_room,
                       user: self.user,
                       status: :blocked,
                       parent_booking_id: self.id)
      end
    end
  end

  def destroy_connected_bookings
    self.children.each do |booking|
      booking.destroy
    end
  end
end
