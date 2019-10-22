require 'date'
class Room < ApplicationRecord
  include ActiveRecord::Sanitization
  belongs_to :house
  has_many :room_units
  has_many :bookings

  def availability_between_dates(dtstart, dtend)
    current_room_bookings = Booking.where('room_id = ? AND ((dtstart >= ? AND dtstart < ?) OR (dtend > ? AND dtend <= ?))',
                                          self.id, dtstart, dtend, dtstart, dtend)
                                .map {|r|  {:dtstart => r.dtstart, :dtend => r.dtend}}
    total_rooms = self.room_units.count

    # join date range and bookings
    date_range = (dtstart..dtend).to_a.map {|r|  {:series => r}}
    payload = []
    date_range.each do |range|
      bookings = current_room_bookings.select { |booking| range[:series] >= booking[:dtstart] && range[:series] < booking[:dtend]} || []
      bookings.each do |booking|
        payload << booking.merge({series: range[:series], count: 1})
      end
      payload << {:series => range[:series], :count => nil} if bookings.empty?
    end

    # group by date and calculate the allotment
    payload = payload.group_by{|r| r[:series]}.map do |key, values|
      {
          date: key.strftime('%Y-%m-%d'),
          allotment: total_rooms - values.select{|r| r[:count] == 1}.count
      }
    end

    # return availability
    {
        total_rooms: total_rooms,
        start_date: dtstart.strftime('%Y-%m-%d'),
        end_date: dtend.strftime('%Y-%m-%d'),
        payload: payload.sort_by {|r| r[:date]}
    }
  end
end
