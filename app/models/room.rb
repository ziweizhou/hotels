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

    sql = <<-SQL
          -- Get active bookings in the range
          with current_booking as (
          select * from bookings b
          inner join generate_series(TIMESTAMP  #{san_dtstart} , TIMESTAMP #{san_dtsend},'1 day') series
          on series >= b.dtstart AND series < b.dtend 
            where b.house_id = 1 and status in (#{connection.quote(:confirmed)},#{connection.quote(:blocked)})
          ),

          -- Find if there is blocked bookings in connected units (child)
          child as (
          select series,
               COUNT(b.id) booking
          from  room_units parent
          inner join room_units child
          on parent.id = child.part_of_room_id and parent.room_id = #{self.id} 
          inner join current_booking b
          on b.room_unit_id = child.id
          group by series
          ),

          -- Find parent bookings
          parent as (
          select series,
               COUNT(parent.id) booking
          from  room_units parent
          inner join current_booking b
          on b.room_unit_id = parent.id and parent.room_id = #{self.id} 
          group by series
          )

          -- Final result set
          select  dates,
          		case when (parent.booking is null or parent.booking = 0) then -- If parent is empty then check if child is blocked
                  case when (child.booking is null or child.booking = 0)  -- If child is blocked consider parent as booked
                      then 0 else 1 
                  end
              else parent.booking end as count -- If parent is not empty take its count
          from generate_series(TIMESTAMP  #{san_dtstart} , TIMESTAMP #{san_dtsend},'1 day') dates
          left join parent
          on parent.series = dates
          left join  child
          on child.series = dates
          order by dates
    SQL

    bookings = connection.execute(sql).to_a
    total_rooms = self.room_units.count


    payload = bookings.map do |booking|
      {
          date: Date.parse(booking['dates']).strftime('%Y-%m-%d'),
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
