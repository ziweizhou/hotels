class Booking < ApplicationRecord
  belongs_to :house
  belongs_to :room, optional: true
  belongs_to :room_type
  belongs_to :user

  belongs_to :parent, class_name: 'Booking', optional: true
  has_many :children, class_name: 'Booking', foreign_key: :parent_booking_id

  after_initialize :init
  # before_create :check_availablity
  # after_create :create_connected_bookings

  private
  def init
    self.status  ||= :unallocated
  end

  def check_availablity
    unless dates_available?
      self.status = 'overlap'
    end
  end

  def dates_available?
    decision_table = {}
    
    # get all bookings which are yet to be allocated including the current booking
    unallocated_bookings = Booking.where(status: [:unallocated])
    unallocated_bookings << self
    
    minDate = ''
    maxDate = ''

    # get all allocated room units and their availability
    allocated_units = Booking.includes(room: [:units])
                              .where(status: [:allocated])
                              .where('(dtstart >= ? AND dtstart < ?) OR (dtend > ? AND dtend <= ?)',
                                    minDate, maxDate, minDate, maxDate ).empty?

    # use greedy algorithm to fit unallocated bookings into the remaining units
    parent_available && children_available
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

  def update_check_availability
    raise('Dates not available') unless dates_available?
  end

  def update_connected_bookings
    self.children.each do |booking|
      booking.update(dtstart: self.dtstart,
                     dtend: self.dtend,
                     user: self.user,
                     status: self.status == 'confirmed' ? :blocked :  self.status
      )
    end
  end

  def destroy_connected_bookings
    self.children.destroy_all
  end
end
