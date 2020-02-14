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
    date_vacancy_map = initialize_date_vacancy_map(dates_enumeration)

    room_bookings = bookings_in_range(bookings, start_date, end_date)
    subroom_bookings = bookings_in_range(
      Booking.with_rooms(consist_of_rooms.select(:room_id)),
      start_date,
      end_date
    )
    superroom_bookings = bookings_in_range(
      Booking.with_rooms(part_of_rooms.select(:room_id)),
      start_date,
      end_date
    )

    update_vacancy_from_assigned_subroom_bookings(
      date_vacancy_map,
      subroom_bookings.assigned,
      start_date,
      end_date
    )
    update_vacancy_from_assigned_room_bookings(
      date_vacancy_map,
      room_bookings.assigned,
      start_date,
      end_date
    )

    update_vacancy_from_unassigned_subroom_bookings(
      date_vacancy_map,
      subroom_bookings.unassigned,
      start_date,
      end_date
    )
    update_vacancy_from_unassigned_room_bookings(
      date_vacancy_map,
      room_bookings.unassigned,
      start_date,
      end_date
    )

    update_vacancy_from_superroom_bookings(
      date_vacancy_map,
      superroom_bookings,
      start_date,
      end_date
    )

    payload = dates_enumeration.map do |date|
      {
        date: date.strftime("%Y-%m-%d"),
        allotment: date_vacancy_map[date].size
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

  def initialize_date_vacancy_map(dates_enumeration)
    date_vacancy_map = dates_enumeration.reduce({}) do |dvm, date|
      if consist_of_rooms.size > 0
        dvm[date] = consist_of_rooms.reduce({}) do |date_vacancy, room_unit|
          date_vacancy[room_unit.part_of_room_id] ||= {}
          date_vacancy[room_unit.part_of_room_id][room_unit.id] = true
          date_vacancy
        end
      else
        dvm[date] = room_units.reduce({}) do |date_vacancy, room_unit|
          date_vacancy[room_unit.id] = {}
          date_vacancy
        end
      end

      dvm
    end
  end

  def update_vacancy_from_assigned_room_bookings(date_vacancy_map, bookings, start_date, end_date)
    bookings.each do |booking|
      booking.get_dates_enumeration(start_date, end_date).each do |date|
        date_vacancy_map[date].delete(booking.room_unit_id)
      end
    end
  end

  def update_vacancy_from_unassigned_room_bookings(date_vacancy_map, bookings, start_date, end_date)
    bookings.each do |booking|
      booking.get_dates_enumeration(start_date, end_date).each do |date|
        date_vacancy = date_vacancy_map[date]

        assigned_unit = date_vacancy.keys.reduce(nil) do |max_vacancy_unit, room_unit_id|
          max_vacancy_unit = room_unit_id if max_vacancy_unit.nil? ||
            date_vacancy[room_unit_id].size > date_vacancy[max_vacancy_unit].size
          max_vacancy_unit
        end

        date_vacancy.delete(assigned_unit) unless assigned_unit.nil?
      end
    end
  end

  def update_vacancy_from_assigned_subroom_bookings(date_vacancy_map, bookings, start_date, end_date)
    to_delete = bookings.reduce({}) do |acc_to_delete, booking|
      booking.get_dates_enumeration(start_date, end_date).each do |date|
        date_vacancy = date_vacancy_map[date]

        assigned_unit = date_vacancy.keys.find do |superroom_unit_id|
          date_vacancy[superroom_unit_id].has_key?(booking.room_unit_id)
        end

        next if assigned_unit.nil?

        date_vacancy[assigned_unit].delete(booking.room_unit_id)

        acc_to_delete[date] ||= {}
        acc_to_delete[date][assigned_unit] = true
      end

      acc_to_delete
    end

    to_delete.keys.each do |date|
      to_delete[date].keys.each do |superroom_unit_id|
        date_vacancy_map[date].delete(superroom_unit_id)
      end
    end
  end

  def update_vacancy_from_unassigned_subroom_bookings(date_vacancy_map, bookings, start_date, end_date)
    to_delete = bookings.reduce({}) do |acc_to_delete, booking|
      booking.get_dates_enumeration(start_date, end_date).each do |date|
        date_vacancy = date_vacancy_map[date]

        assigned_unit = date_vacancy.keys.reduce(nil) do |min_vacancy_unit, superroom_unit_id|
          min_vacancy_unit.nil? ||
          date_vacancy[superroom_unit_id].size < date_vacancy[min_vacancy_unit].size ?
            superroom_unit_id :
            min_vacancy_unit
        end

        next if assigned_unit.nil?

        assigned_subroom_id = date_vacancy[assigned_unit].keys.first
        date_vacancy[assigned_unit].delete(assigned_subroom_id)

        acc_to_delete[date] ||= {}
        acc_to_delete[date][assigned_unit] = true
      end

      acc_to_delete
    end

    to_delete.keys.each do |date|
      to_delete[date].keys.each do |superroom_unit_id|
        date_vacancy_map[date].delete(superroom_unit_id)
      end
    end
  end

  def update_vacancy_from_superroom_bookings(date_vacancy_map, bookings, start_date, end_date)
    num_of_subroom_units = room_units.map(&:part_of_room_id).compact.uniq.length

    bookings.each do |booking|
      booking.get_dates_enumeration(start_date, end_date).each do |date|
        date_vacancy = date_vacancy_map[date]

        num_of_subroom_units.times do
          date_vacancy.delete(date_vacancy.keys.first)
        end
      end
    end
  end
end