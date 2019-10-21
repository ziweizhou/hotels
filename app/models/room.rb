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
              WITH current_room_bookings AS (
                 SELECT *
                 FROM bookings
                 WHERE bookings.room_id = #{self.id}
                   AND bookings.dtstart >= #{san_dtstart} and bookings.dtend < #{san_dtsend}
                 ),

                 current_room_blocks AS
                (SELECT DISTINCT a.room_unit_id,
                                 c.id
                 FROM current_room_bookings A
                 INNER JOIN room_units B ON a.room_unit_id = b.id
                 LEFT JOIN room_units C ON c.id = b.part_of_room_id
                 OR c.part_of_room_id = b.id)

              SELECT series,
                     Count(DISTINCT bookings.room_unit_id) + Count(DISTINCT blocks.id) as count
              FROM generate_series(#{san_dtstart},#{san_dtsend},interval '1 day') series
              LEFT JOIN current_room_bookings bookings ON series >= bookings.dtstart
              AND series < bookings.dtend
              LEFT JOIN current_room_blocks blocks ON bookings.room_unit_id = blocks.room_unit_id
              GROUP BY series
              ORDER BY series").to_a
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
