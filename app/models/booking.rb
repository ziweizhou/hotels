# frozen_string_literal: true

class Booking < ApplicationRecord
  belongs_to :house
  belongs_to :room, optional: true
  belongs_to :room_type
  belongs_to :user

  belongs_to :parent, class_name: 'Booking', optional: true
  has_many :children, class_name: 'Booking', foreign_key: :parent_booking_id

  after_initialize :init
  before_create :before_create_hook

  def init
    @lookup_dates_units = {}
    @lookup_dates_rooms = {}
    @allocations = []
    self.status ||= :unallocated
  end

  def before_create_hook
    # get all bookings which are yet to be allocated including the current booking
    unallocated_bookings = Booking.includes(room: :room_unit).where(status: [:unallocated]).to_a.sort_by! { |b| (b.dtend - b.dtend).to_i + 1 }.reverse

    unallocated_bookings << self

    minDate = unallocated_bookings.min_by(&:dtstart).dtstart
    maxDate = unallocated_bookings.max_by(&:dtend).dtend
    try_virtual_allocations(unallocated_bookings, minDate, maxDate)
    raise 'Error' if @allocations.count < unallocated_bookings.count

    self.status = :unallocated
  end

  def check_availability(dtstart, dtend)
    unallocated_bookings = Booking.includes(room: :room_unit)
                                  .where('((dtstart >= ? AND dtstart < ?) OR (dtend > ? AND dtend <= ?)) AND status in (?) ', dtstart, dtend, dtstart, dtend, :unallocated)
                                  .to_a.sort_by! { |b| (b.dtend - b.dtend).to_i + 1 }.reverse

    try_virtual_allocations(unallocated_bookings, dtstart, dtend)
  end

  def room_status(dtstart, dtend)
    result = []
    @all_rooms.each do |room|
      flag = true
      dtstart.upto(dtend) do |series|
        next if series == dtend

        unless @lookup_dates_rooms[series] && @lookup_dates_rooms[series][room[:id]].nil?
          flag = false
          break
        end
      end
      result << room if flag
    end
    result
  end

  def try_virtual_allocations(unallocated_bookings, minDate, maxDate)
    connection = ActiveRecord::Base.connection
    @all_rooms = Room.includes(:room_units, :room_type).map do |room|
      {
        id: room.id,
        name: room.name,
        room_type_id: room.room_type_id,
        room_type: room.room_type.name,
        unit_count: room.room_units.count,
        units: room.room_units.map(&:unit_id)
      }
    end.to_a.sort_by { |r| r[:unit_count] }

    @all_units = RoomUnit.all.to_a

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
      set_decision_table(allocation['series'], allocation['unit_id'])
    end
    # use greedy algorithm to fit unallocated bookings into the remaining units
    unallocated_bookings.each do |booking|
      availability = check_available(booking)
      raise 'not available' unless availability
    end

    @allocations
  end

  def check_available(booking)
    available = false
    found = nil
    # search through rooms
    @all_rooms.select { |room| room[:room_type_id] == booking.room_type_id && room[:status].nil? }.each do |room|
      found = true
      # see if all dates are available in the room for that booking
      booking.dtstart.upto(booking.dtend) do |series|
        next if series == booking.dtend # ignore dtend

        units = @lookup_dates_units[series] || []
        # check if all units are available
        room[:units].each do |unit|
          next unless units.include?(unit)

          # the unit is not available, move on to next room
          found = false
          break
        end
        break unless found
      end
      if found
        allocate_room(room, booking)
        break
      end
    end

    found
  end

  def allocate_room(room, booking)
    @allocations.push(
      room: room,
      booking: booking
    )
    booking.dtstart.upto(booking.dtend) do |series|
      next if series == booking.dtend

      set_lookup_table(@lookup_dates_rooms, series, room[:id], :ALLOCATED)
    end

    room[:units].each do |unit|
      booking.dtstart.upto(booking.dtend) do |series|
        next if series == booking.dtend

        set_lookup_table(@lookup_dates_units, series, unit, true) unless series == booking.dtend # ignore end date
      end
      @all_units.select { |r| r[:unit_id] == unit && r[:room_id] != room[:id] }&.each do |unit|
        booking.dtstart.upto(booking.dtend) do |series|
          next if series == booking.dtend

          set_lookup_table(@lookup_dates_rooms, series, unit[:room_id], :SHARED_BLOCKED)
        end
      end
    end
  end

  def set_lookup_table(table, date, key, value)
    table[date] = {} unless table[date]
    table[date][key] = value
  end
end
