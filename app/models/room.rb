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
    date_occupancy_map = {}

    consist_of_room_bookings = Booking.with_rooms(consist_of_rooms.select(:room_id))
    part_of_room_bookings = Booking.with_rooms(part_of_rooms.select(:room_id))

    [
      bookings,
      consist_of_room_bookings,
      part_of_room_bookings
    ].each do |bookings|
      bookings_in_scope = bookings.confirmed
      bookings_in_range = bookings_in_scope.in_between(start_date, end_date)

      update_date_occupancy_map(date_occupancy_map, bookings_in_range, start_date, end_date)
    end

    payload = dates_enumeration.map do |date|
      date_occupancy = date_occupancy_map.has_key?(date) ? date_occupancy_map[date] : 0

      {
        date: date.strftime("%Y-%m-%d"),
        allotment: [total_room_units - date_occupancy, 0].max
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

  def update_date_occupancy_map(date_occupancy_map, bookings, start_date, end_date)
    bookings.each do |booking|
      booking_start = [start_date, booking.dtstart].max
      booking_end = [end_date, booking.dtend - 1.day].min

      booking_start.upto(booking_end) do |date|
        if date_occupancy_map.has_key?(date)
          date_occupancy_map[date] += 1
        else
          date_occupancy_map[date] = 1
        end
      end
    end
  end
end