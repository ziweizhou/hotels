require 'date'

class Room < ApplicationRecord
  include ActiveRecord::Sanitization
  belongs_to :house
  has_many :room_units
  has_many :consist_of_rooms, through: :room_units
  has_many :part_of_rooms, through: :room_units
  has_many :bookings

  def availability_between_dates(start_date_str, end_date_str)
    start_date = parse_date(start_date_str)
    end_date = parse_date(end_date_str)
    dates_enumeration = start_date.upto(end_date)
    date_map = initialize_date_map(dates_enumeration)
    bookings_map = {
      room_bookings: bookings,
      subroom_bookings: Booking.with_rooms(consist_of_rooms.select(:room_id)),
      superroom_bookings: Booking.with_rooms(part_of_rooms.select(:room_id))
    }

    [:assigned, :unassigned].each do |scope|
      bookings_map.each do |(bookings_type, bookings)|
        update_date_map(date_map, bookings, bookings_type, scope, start_date, end_date)
      end
    end

    date_map[:to_delete].keys.each do |date|
      date_map[:to_delete][date].keys.each do |assigned_unit|
        date_map[:vacancy][date].delete(assigned_unit)
      end
    end

    {
      total_rooms: room_units.count,
      start_date: to_date_str(start_date),
      end_date: to_date_str(end_date),
      payload: dates_enumeration.map do |date|
        {
          date: to_date_str(date),
          allotment: date_map[:vacancy][date].size
        }
      end
    }
  end

  private

  def initialize_date_map(dates_enumeration)
    subroom_units = RoomUnit.with_rooms(consist_of_rooms.select(:room_id))

    dates_enumeration.reduce({ vacancy: {}, subroom_vacancy: {}, to_delete: {} }) do |dm, date|
      unless consist_of_rooms.empty?
        dm[:subroom_vacancy][date] = subroom_units.reduce({}) do |date_subroom_vacancy, subroom_unit|
          date_subroom_vacancy[subroom_unit.room_id] ||= {}
          date_subroom_vacancy[subroom_unit.room_id][subroom_unit.id] = true
          date_subroom_vacancy
        end

        dm[:vacancy][date] = consist_of_rooms.reduce({}) do |date_vacancy, room_unit|
          date_vacancy[room_unit.part_of_room_id] ||= {}
          date_vacancy[room_unit.part_of_room_id][room_unit.id] = true

          remove_from_date_subroom_vacancy(dm[:subroom_vacancy][date], room_unit.room_id, room_unit.id)

          date_vacancy
        end
      else
        dm[:vacancy][date] = room_units.reduce({}) do |date_vacancy, room_unit|
          date_vacancy.merge(room_unit.id => {})
        end
      end

      dm
    end
  end

  def update_date_map(date_map, bookings, bookings_type, scope, start_date, end_date)
    bookings_in_range = bookings.confirmed.in_between(start_date, end_date).send(scope)
    args = [date_map, bookings_in_range, start_date, end_date]
    send(:"update_date_map_from_#{scope}_#{bookings_type}", *args)
  end

  def update_date_map_from_assigned_room_bookings(date_map, bookings, start_date, end_date)
    each_booking_date(bookings, start_date, end_date) do |booking, date|
      date_map[:vacancy][date].delete(booking.room_unit_id)
    end
  end

  def update_date_map_from_unassigned_room_bookings(date_map, bookings, start_date, end_date)
    each_booking_date(bookings, start_date, end_date) do |booking, date|
      date_vacancy = date_map[:vacancy][date]

      assigned_unit = date_vacancy.keys.max do |a_unit_id, b_unit_id|
        date_vacancy[a_unit_id].size <=> date_vacancy[b_unit_id].size
      end

      date_vacancy.delete(assigned_unit) unless assigned_unit.nil?
    end
  end


  def update_date_map_from_assigned_subroom_bookings(date_map, bookings, start_date, end_date)
    each_booking_date(bookings, start_date, end_date) do |booking, date|
      date_subroom_vacancy = date_map[:subroom_vacancy][date]
      room_id = booking.room_id
      room_unit_id = booking.room_unit_id

      if (
        date_subroom_vacancy.has_key?(room_id) &&
        date_subroom_vacancy[room_id].has_key?(room_unit_id)
      )
        remove_from_date_subroom_vacancy(date_subroom_vacancy, room_id, room_unit_id)
        next
      end

      date_vacancy = date_map[:vacancy][date]

      assigned_unit = date_vacancy.keys.find do |superroom_unit_id|
        date_vacancy[superroom_unit_id].has_key?(room_unit_id)
      end

      next if assigned_unit.nil?

      date_vacancy[assigned_unit].delete(room_unit_id)

      date_map[:to_delete][date] ||= {}
      date_map[:to_delete][date][assigned_unit] = true
    end
  end

  def update_date_map_from_unassigned_subroom_bookings(date_map, bookings, start_date, end_date)
    each_booking_date(bookings, start_date, end_date) do |booking, date|
      date_subroom_vacancy = date_map[:subroom_vacancy][date]
      room_id = booking.room_id

      if date_subroom_vacancy.has_key?(booking.room_id)
        assigned_unit = date_subroom_vacancy[room_id].keys.first
        remove_from_date_subroom_vacancy(date_subroom_vacancy, room_id, assigned_unit)
        next
      end

      date_vacancy = date_map[:vacancy][date]

      assigned_unit = date_vacancy.keys.min do |a_unit_id, b_unit_id|
        date_vacancy[a_unit_id].size <=> date_vacancy[b_unit_id].size
      end

      next if assigned_unit.nil?

      assigned_subroom_id = date_vacancy[assigned_unit].keys.first
      date_vacancy[assigned_unit].delete(assigned_subroom_id)

      date_map[:to_delete][date] ||= {}
      date_map[:to_delete][date][assigned_unit] = true
    end
  end

  def update_date_map_from_assigned_superroom_bookings(date_map, bookings, start_date, end_date)
    return if bookings.empty?

    subroom_units_map = get_subroom_units_map

    each_booking_date(bookings, start_date, end_date) do |booking, date|
      date_vacancy = date_map[:vacancy][date]

      subroom_units_map[booking.room_unit_id].keys.each do |subroom_unit_id|
        date_vacancy.delete(subroom_unit_id)
      end
    end
  end

  def update_date_map_from_unassigned_superroom_bookings(date_map, bookings, start_date, end_date)
    return if bookings.empty?

    subroom_units_map = get_subroom_units_map

    each_booking_date(bookings, start_date, end_date) do |booking, date|
      date_vacancy = date_map[:vacancy][date]
      get_vacant_subrooms = -> superroom_unit_id {
        subroom_units_map[superroom_unit_id].keys.count do |subroom_unit_id|
          date_vacancy.has_key?(subroom_unit_id)
        end
      }

      assigned_unit = subroom_units_map.keys.max do |a_unit_id, b_unit_id|
        get_vacant_subrooms.call(a_unit_id) <=> get_vacant_subrooms.call(b_unit_id)
      end

      next if assigned_unit.nil?

      subroom_units_map[assigned_unit].keys.each do |subroom_unit_id|
        date_vacancy.delete(subroom_unit_id)
      end
    end
  end

  def remove_from_date_subroom_vacancy(date_subroom_vacancy, room_id, room_unit_id)
    date_subroom_vacancy[room_id].delete(room_unit_id)

    if date_subroom_vacancy[room_id].empty?
      date_subroom_vacancy.delete(room_id)
    end
  end

  def get_subroom_units_map
    room_units.reduce({}) do |acc, room_unit|
      acc[room_unit.part_of_room_id] ||= {}
      acc[room_unit.part_of_room_id][room_unit.id] = true
      acc
    end
  end

  def each_booking_date(bookings, start_date, end_date)
    bookings.each do |booking|
      booking.get_dates_enumeration(start_date, end_date).each do |date|
        yield(booking, date)
      end
    end
  end

  def parse_date(date_str)
    date_str.is_a?(Date) ? date_str : Date.parse(date_str)
  end

  def to_date_str(date)
    date.strftime("%Y-%m-%d")
  end
end