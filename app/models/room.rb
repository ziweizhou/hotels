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
          -- Get all booking across rooms in the given range
            WITH current_room_bookings AS
          ( SELECT *
            FROM bookings
            WHERE bookings.house_id =  #{self.house_id} and (bookings.dtstart >= #{san_dtstart}  AND bookings.dtstart < #{san_dtsend})
             OR (bookings.dtend > #{san_dtstart}  AND bookings.dtend <= #{san_dtsend})
           ),

          -- Get room unit connection information
           connected_rooms AS
          (SELECT DISTINCT b.id primary_unit_id,
                           b.room_id primary_room_id,
                           c.id connected_unit_id,
                           c.room_id connected_room_id
           FROM current_room_bookings A
           INNER JOIN room_units B ON a.room_unit_id = b.id
           LEFT JOIN room_units C ON c.id = b.part_of_room_id
           OR c.part_of_room_id = b.id
           ),

          -- Connect Bookings => Room Units => Connected Room Units
           combined1 AS
          (SELECT series,
                  bookings.room_id,
                  blocks.*
           FROM generate_series(#{san_dtstart}, #{san_dtsend},interval '1 day') series
           LEFT JOIN current_room_bookings bookings ON series >= bookings.dtstart
           AND series < bookings.dtend
           LEFT JOIN connected_rooms blocks ON bookings.room_unit_id IN (blocks.primary_unit_id,
                                                                         blocks.connected_unit_id)
           AND bookings.room_id IN(blocks.primary_room_id,
                                   blocks.primary_room_id)),

          -- Filter the current room
           combined2 AS
          (
           SELECT series, primary_unit_id AS book
           FROM combined1 WHERE primary_room_id =  #{self.id}
           UNION
           SELECT series, connected_unit_id
           FROM combined1 WHERE connected_room_id =  #{self.id}
           UNION
           SELECT distinct series, null::bigint
           FROM combined1
           )

          -- Get count of booking for each date
          SELECT series,
                 count(book)
          FROM combined2
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
