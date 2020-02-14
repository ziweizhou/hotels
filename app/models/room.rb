require 'date'
class Room < ApplicationRecord
  include ActiveRecord::Sanitization
  belongs_to :house
  # belongs_to :room_type
  has_many :room_units
  has_many :units, through: :room_units
  has_many :bookings

  def availability_between_dates(start_date_str, end_date_str)
    start_date = start_date_str.is_a?(Date) ? start_date_str : Date.parse(start_date_str)
    end_date = end_date_str.is_a?(Date) ? end_date_str : Date.parse(end_date_str)
    dates_enumeration = start_date.upto(end_date)
    total_room_units = room_units.count
    date_allotment_map = dates_enumeration.reduce({}) do |acc, date|
      acc[date] = total_room_units
      acc
    end

    bookings_in_range = bookings.confirmed.in_between(start_date, end_date)

    update_date_allotment_map(date_allotment_map, bookings_in_range.assigned)
    update_date_allotment_map(date_allotment_map, bookings_in_range.unassigned)

    payload = dates_enumeration.map do |date|
      {
        date: date.strftime("%Y-%m-%d"),
        allotment: date_allotment_map[date]
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

  def update_date_allotment_map(date_allotment_map, bookings)
    bookings.each do |booking|
      booking.dtstart.upto(booking.dtend - 1.day) do |date|
        if date_allotment_map.has_key?(date) && date_allotment_map[date] > 0
          date_allotment_map[date] -= 1
        end
      end
    end
  end
end