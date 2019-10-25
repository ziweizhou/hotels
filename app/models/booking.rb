class Booking < ApplicationRecord
  belongs_to :house
  belongs_to :room
  belongs_to :room_unit
  belongs_to :user

  belongs_to :parent, class_name: 'Booking', optional: true
  has_many :children, class_name: 'Booking', foreign_key: :parent_booking_id

  after_initialize :init
  before_create :check_overlap, if: Proc.new {|booking|  booking.status == 'confirmed'}
  after_create :create_connected_bookings, if: Proc.new {|booking| booking.room_unit.virtual}
  after_update :update_connected_bookings, if: Proc.new {|booking| booking.room_unit.virtual}
  after_destroy :destroy_connected_bookings, if: Proc.new {|booking| booking.room_unit.virtual}

  private
  def init
    self.status  ||= :confirmed
  end

  def check_overlap
    # todo check for connected units
    unless dates_available?
      self.status = 'overlap'
    end
  end

  def dates_available?
    Booking.where('room_unit_id = ? AND ((dtstart >= ? AND dtstart < ?) OR (dtend > ? AND dtend <= ?)) AND status in (?,?) ',
                  self.room_unit_id, self.dtstart, self.dtend, self.dtstart, self.dtend, :confirmed, :blocked).empty?
  end

  def create_connected_bookings
    room_unit.consist_of_rooms.each do |connected_room|
      Booking.create(dtstart: self.dtstart,
                     dtend: self.dtend,
                     house: self.house,
                     room: connected_room.room,
                     room_unit: connected_room,
                     user: self.user,
                     status: self.status == 'confirmed' ? :blocked :  self.status,
                     parent_booking_id: self.id)
    end
  end

  def update_connected_bookings
    if dates_available?
      self.children.each do |booking|
        booking.update(dtstart: self.dtstart,
                       dtend: self.dtend,
                       user: self.user,
                       status: self.status == 'confirmed' ? :blocked :  self.status
        )
      end
    else
      Raise('Dates not available')
    end
  end

  def destroy_connected_bookings
    self.children.destroy_all
  end
end
