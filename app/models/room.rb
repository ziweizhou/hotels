require 'date'

class Room < ApplicationRecord
  include ActiveRecord::Sanitization
  belongs_to :house
  # belongs_to :room_type
  has_many :room_units
  has_many :units, through: :room_units
  has_many :consist_of_rooms, through: :room_units
  has_many :part_of_rooms, through: :room_units
  has_many :bookings

  def availability_between_dates(start_date_str, end_date_str)
    start_date = start_date_str.is_a?(Date) ? start_date_str : Date.parse(start_date_str)
    end_date = end_date_str.is_a?(Date) ? end_date_str : Date.parse(end_date_str)
    dates_enumeration = start_date.upto(end_date)
    total_room_units = room_units.count
    date_map = initialize_date_map(dates_enumeration)

    room_bookings, subroom_bookings, superroom_bookings = [
      bookings,
      Booking.with_rooms(consist_of_rooms.select(:room_id)),
      Booking.with_rooms(part_of_rooms.select(:room_id))
    ].map do |bookings|
      bookings.confirmed.in_between(start_date, end_date)
    end

    [:assigned, :unassigned].each do |scope|
      {
        room_bookings: room_bookings,
        subroom_bookings: subroom_bookings,
        superroom_bookings: superroom_bookings
      }.each do |(bookings_type, bookings)|
        update_date_map(date_map, bookings, bookings_type, scope, start_date, end_date)
      end
    end

    date_map[:to_delete].keys.each do |date|
      date_map[:to_delete][date].keys.each do |assigned_unit|
        date_map[:vacancy][date].delete(assigned_unit)
      end
    end

    payload = dates_enumeration.map do |date|
      {
        date: date.strftime("%Y-%m-%d"),
        allotment: date_map[:vacancy][date].size
      }
    end

    {
      total_rooms: total_room_units,
      start_date: start_date_str,
      end_date: end_date_str,
      payload: payload
    }
  end

  private

  def bookings_in_range(bookings, start_date, end_date)
    bookings_in_scope = bookings.confirmed
    bookings_in_scope.in_between(start_date, end_date)
  end

  def initialize_date_map(dates_enumeration)
    dates_enumeration.reduce({ vacancy: {}, to_delete: {} }) do |dm, date|
      if consist_of_rooms.size > 0
        dm[:vacancy][date] = consist_of_rooms.reduce({}) do |date_vacancy, room_unit|
          date_vacancy[room_unit.part_of_room_id] ||= {}
          date_vacancy[room_unit.part_of_room_id][room_unit.id] = true
          date_vacancy
        end
      else
        dm[:vacancy][date] = room_units.reduce({}) do |date_vacancy, room_unit|
          date_vacancy[room_unit.id] = {}
          date_vacancy
        end
      end

      dm
    end
  end

  def update_date_map(date_map, bookings, bookings_type, scope, start_date, end_date)
    args = [date_map, bookings.send(scope), start_date, end_date]

    case :"#{scope}_#{bookings_type}"
    when :assigned_room_bookings
      update_date_map_from_assigned_room_bookings(*args)
    when :unassigned_room_bookings
      update_date_map_from_unassigned_room_bookings(*args)
    when :assigned_subroom_bookings
      update_date_map_from_assigned_subroom_bookings(*args)
    when :unassigned_subroom_bookings
      update_date_map_from_unassigned_subroom_bookings(*args)
    when :assigned_superroom_bookings
      update_date_map_from_assigned_superroom_bookings(*args)
    when :unassigned_superroom_bookings
      update_date_map_from_unassigned_superroom_bookings(*args)
    end
  end

  def update_date_map_from_assigned_room_bookings(date_map, bookings, start_date, end_date)
    bookings.each do |booking|
      booking.get_dates_enumeration(start_date, end_date).each do |date|
        date_map[:vacancy][date].delete(booking.room_unit_id)
      end
    end
  end

  def update_date_map_from_unassigned_room_bookings(date_map, bookings, start_date, end_date)
    bookings.each do |booking|
      booking.get_dates_enumeration(start_date, end_date).each do |date|
        date_vacancy = date_map[:vacancy][date]

        assigned_unit = date_vacancy.keys.reduce(nil) do |max_vacancy_unit, room_unit_id|
          max_vacancy_unit = room_unit_id if max_vacancy_unit.nil? ||
            date_vacancy[room_unit_id].size > date_vacancy[max_vacancy_unit].size
          max_vacancy_unit
        end

        date_vacancy.delete(assigned_unit) unless assigned_unit.nil?
      end
    end
  end

  def update_date_map_from_assigned_subroom_bookings(date_map, bookings, start_date, end_date)
    bookings.each do |booking|
      booking.get_dates_enumeration(start_date, end_date).each do |date|
        date_vacancy = date_map[:vacancy][date]

        assigned_unit = date_vacancy.keys.find do |superroom_unit_id|
          date_vacancy[superroom_unit_id].has_key?(booking.room_unit_id)
        end

        next if assigned_unit.nil?

        date_vacancy[assigned_unit].delete(booking.room_unit_id)

        date_map[:to_delete][date] ||= {}
        date_map[:to_delete][date][assigned_unit] = true
      end
    end
  end

  def update_date_map_from_unassigned_subroom_bookings(date_map, bookings, start_date, end_date)
    bookings.each do |booking|
      booking.get_dates_enumeration(start_date, end_date).each do |date|
        date_vacancy = date_map[:vacancy][date]

        assigned_unit = date_vacancy.keys.reduce(nil) do |min_vacancy_unit, superroom_unit_id|
          (min_vacancy_unit.nil? ||
          date_vacancy[superroom_unit_id].size < date_vacancy[min_vacancy_unit].size) ?
            superroom_unit_id :
            min_vacancy_unit
        end

        next if assigned_unit.nil?

        assigned_subroom_id = date_vacancy[assigned_unit].keys.first
        date_vacancy[assigned_unit].delete(assigned_subroom_id)

        date_map[:to_delete][date] ||= {}
        date_map[:to_delete][date][assigned_unit] = true
      end
    end
  end

  def update_date_map_from_assigned_superroom_bookings(date_map, bookings, start_date, end_date)
    return if bookings.length === 0

    subroom_units = RoomUnit.where(part_of_room_id: bookings.select(:room_unit_id))

    subroom_units_map = subroom_units.reduce({}) do |acc, subroom_unit|
      acc[subroom_unit.part_of_room_id] ||= {}
      acc[subroom_unit.part_of_room_id][subroom_unit.id] = true
      acc
    end

    bookings.each do |booking|
      booking.get_dates_enumeration(start_date, end_date).each do |date|
        date_vacancy = date_map[:vacancy][date]

        subroom_units_map[booking.room_unit_id].keys.each do |subroom_unit_id|
          date_vacancy.delete(subroom_unit_id)
        end
      end
    end
  end

  def update_date_map_from_unassigned_superroom_bookings(date_map, bookings, start_date, end_date)
    return if bookings.length === 0

    subroom_units_map = room_units.reduce({}) do |acc, room_unit|
      acc[room_unit.part_of_room_id] ||= {}
      acc[room_unit.part_of_room_id][room_unit.id] = true
      acc
    end

    bookings.each do |booking|
      booking.get_dates_enumeration(start_date, end_date).each do |date|
        date_vacancy = date_map[:vacancy][date]

        superroom_assignment = subroom_units_map.keys.reduce({}) do |acc, superroom_unit_id|
          vacant_subrooms = subroom_units_map[superroom_unit_id].keys.count do |subroom_unit_id|
            date_vacancy.has_key?(subroom_unit_id)
          end

          if !acc.has_key?(:max_vacant_subrooms) || vacant_subrooms > acc[:max_vacant_subrooms]
            acc[:max_vacant_subrooms] = vacant_subrooms
            acc[:assigned_superroom_unit_id] = superroom_unit_id
          end

          acc
        end

        if superroom_assignment.has_key?(:assigned_superroom_unit_id)
          assigned_superroom_unit_id = superroom_assignment[:assigned_superroom_unit_id]
          subroom_units_map[assigned_superroom_unit_id].keys.each do |subroom_unit_id|
            date_vacancy.delete(subroom_unit_id)
          end
        end
      end
    end
  end
end