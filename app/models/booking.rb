# frozen_string_literal: true

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

  def init
    self.status ||= :unallocated
  end

  def check_availablity
    self.status = :unallocated unless dates_available?
  end

  def self.dates_available?
    connection = ActiveRecord::Base.connection
    decision_table = {}

    all_room_units = Unit.all.to_a
    all_rooms = Room.includes(:room_units).map do |room|
      {
        id: room.id,
        name: room.name,
        room_type_id: room.room_type_id,
        unit_count: room.room_units.count,
        units: room.room_units.map(&:unit_id)
      }
    end.to_a.sort_by{|r| r[:unit_count]}

    # get all bookings which are yet to be allocated including the current booking
    unallocated_bookings = Booking.includes(room: :room_unit).where(status: [:unallocated]).to_a.sort_by! { |b| (b.dtend - b.dtend).to_i + 1 }.reverse

    # unallocated_bookings << self

    minDate = unallocated_bookings.min_by(&:dtstart).dtstart
    maxDate = unallocated_bookings.max_by(&:dtend).dtend

    # get all allocated room units and their availability
    sql = <<-SQL
          select distinct series, C.room_id, C.unit_id
          from bookings A
          inner join room_units C
            on c.room_id = A.room_id
          inner join generate_series(TIMESTAMP  #{connection.quote(minDate.strftime('%m/%d/%Y'))},
                                     TIMESTAMP  #{connection.quote(maxDate.strftime('%m/%d/%Y'))}, '1 day') series
            on series >= A.dtstart OR series < A.dtend
          where A.status = 'allocated'
    SQL

    allocated_units = connection.execute(sql).to_a
    allocated_units.each do |allocation|
      all_rooms.find { |room| room[:id] == allocation['room_id'] }[:allocated] = true
      Booking.set_decision_table(allocation['series'], allocation['unit_id'], decision_table)
    end
    # use greedy algorithm to fit unallocated bookings into the remaining units
    unallocated_bookings.each do |booking|
      raise 'not available' unless check_available(all_rooms, booking, decision_table)
    end
    puts decision_table
  end

  def self.check_available(rooms, booking, decision_table)
    available = false
    found = nil
    rooms.select { |room| room[:room_type_id] == booking.room_type_id }.each do |room|
      found = true
      if room[:allocated]
        found = false
      else
        booking.dtstart.upto(booking.dtend) do |series|
          units = decision_table[series] || []
          # check if all units are available
          room[:units].each do |unit|
            next unless units.include?(unit)

            # then the unit is not available, move on to next
            found = false
            break
          end
          break unless found
        end
      end
      if found
        allocate_room(room, booking, decision_table)
        break
      end
    end
    
    found
  end
  
  def self.allocate_room(room, booking, decision_table)
    puts booking
    puts room
    room[:allocated] = true
    room[:units].each do |unit|
      booking.dtstart.upto(booking.dtend) do |series|
        set_decision_table(series, unit, decision_table)
      end
    end
  end

  def self.set_decision_table(date, unit, decision_table)
    decision_table[date] = {} unless decision_table[date]
    decision_table[date][unit] = true
  end

  def create_connected_bookings
    room_unit.consist_of_rooms.each do |connected_room|
      Booking.create(dtstart: dtstart,
                     dtend: dtend,
                     house: house,
                     room: connected_room.room,
                     room_unit: connected_room,
                     user: user,
                     status: self.status == 'confirmed' ? :blocked : self.status,
                     parent_booking_id: id)
    end
  end

  def update_check_availability
    raise('Dates not available') unless dates_available?
  end

  def update_connected_bookings
    children.each do |booking|
      booking.update(dtstart: dtstart,
                     dtend: dtend,
                     user: user,
                     status: self.status == 'confirmed' ? :blocked : self.status)
    end
  end

  def destroy_connected_bookings
    children.destroy_all
  end
end
