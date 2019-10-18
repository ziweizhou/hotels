require 'date'
class Room < ApplicationRecord
  include ActiveRecord::Sanitization
  belongs_to :house
  has_many :room_units
  has_many :bookings

  def availability_between_dates(dtstart, dtend)
    # sanitize inputs
    san_dtstart = ActiveRecord::Base.connection.quote(dtstart.strftime('%m/%d/%Y'))
    san_dtsend = ActiveRecord::Base.connection.quote(dtend.strftime('%m/%d/%Y'))
    bookings = ActiveRecord::Base.connection.execute("select days,  case when bookings.room_id is null then 0 else count(*) end as count
                                                      from bookings 
                                                      right join generate_series(#{san_dtstart},#{san_dtsend},interval '1 day') days
                                                      on days >= bookings.dtstart and  days < bookings.dtend 
                                                      where bookings.room_id = #{self.id} OR bookings.room_id is null
                                                      group by days, bookings.room_id
                                                      order by days").to_a
    total_rooms = self.room_units.count

    payload = bookings.map do |booking|
      {
          date: Date.parse(booking['days']).strftime('%Y-%m-%d'),
          allotment: total_rooms - booking['count']
      }
    end

    {
        total_rooms: total_rooms,
        "start_date": "2019-10-11",
        "end_date": "2020-10-20",
        payload: payload
    }
  end
end
