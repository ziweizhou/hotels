require 'date'
class Room < ApplicationRecord
  include ActiveRecord::Sanitization
  belongs_to :house
  has_many :room_units
  has_many :bookings

  def availability_between_dates(dtstart, dtend)
    current_room_bookings = Booking.where('room_id = ? AND ((dtstart >= ? AND dtstart < ?) OR (dtend > ? AND dtend <= ?))',
                                          self.id, dtstart, dtend, dtstart, dtend)
    
    total_rooms = self.room_units.count

    current_room_bookings = current_room_bookings.map {|r|  {:dtstart => r.dtstart, :dtend => r.dtend, :count => 1}}
    date_range = (dtstart..dtend).to_a.map {|r|  {:series => r, :count => nil}}
    
    # merge bookings and date ranges
    payload = date_range.map { |range| range.merge(current_room_bookings.find { |booking| range[:series] >= booking[:dtstart] && range[:series] < booking[:dtend] }  || {}) }
    payload = payload.group_by{|r| r[:series]}.map do |key, values|
      {
          date: key.strftime('%Y-%m-%d'),
          allotment: total_rooms - values.select{|r| r[:count] == 1}.count
      }
    end
    {
        total_rooms: total_rooms,
        start_date: dtstart.strftime('%Y-%m-%d'),
        end_date: dtend.strftime('%Y-%m-%d'),
        payload: payload.sort_by {|r| r[:date]}
    }
  end
end
