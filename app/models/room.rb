require 'date'
class Room < ApplicationRecord
  include ActiveRecord::Sanitization
  belongs_to :house
  has_many :room_units
  has_many :bookings

  def availability_between_dates(dtstart, dtend)
    # sanitize inputs
    connection = ActiveRecord::Base.connection
    san_dtstart = connection.quote(dtstart.strftime('%m/%d/%Y'))
    san_dtsend = connection.quote(dtend.strftime('%m/%d/%Y'))
    bookings = connection.execute("
        with current_room_bookings as (
          select * from bookings 
          where bookings.room_id = #{self.id} and bookings.dtstart >= #{san_dtstart} and bookings.dtend < #{san_dtsend}
        )
        select series, case when bookings.room_id is null then 0 else count(*) end as count
        from generate_series(#{san_dtstart},#{san_dtsend},interval '1 day') series
        left join current_room_bookings bookings
        on series >= bookings.dtstart and  series < bookings.dtend 
        group by series, bookings.room_id
        order by series").to_a
    total_rooms = self.room_units.count

    payload = bookings.map do |booking|
      {
          date: Date.parse(booking['series']).strftime('%Y-%m-%d'),
          allotment: total_rooms - booking['count']
      }
    end

    {
        total_rooms: total_rooms,
        start_date: dtstart.strftime('%Y-%m-%d'),
        end_date: dtend.strftime('%Y-%m-%d'),
        payload: payload
    }
  end
end
