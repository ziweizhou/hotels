# hotels
Assuming you have following data structure 
![ERD Diagram](https://www.evernote.com/l/AB4Hff6e_XRPb6zYU07vnvJ9cgRTwL4XvM4)


### You run these mockup to build the seed data
```
  puts 'create houses'
  1.times.each do
    house = House.create!(is_master: true,
      status: :listed,
      name: Faker::GameOfThrones.character,
      address: Faker::Address.full_address,
    )
    #each hotel will have 3 room types
    3.times.each do
      room = house.rooms.create!(is_master: true,
        name: Faker::GameOfThrones.character
      )
      #each room type will have 10 rooms
      10.times.each do
        room.room_units.create!(room_no: Faker::Number.number(4), house: house)
      end
      puts "create bookings"
      20.times.each do
        future_dtstart = Date.current.tomorrow + rand(10)
        future_dtend = future_dtstart + (1 + rand(10))
        past_dtend = Date.current.yesterday - rand(10)
        past_dtstart = past_dtend - (1 + rand(10))
        [[future_dtstart, future_dtend], [past_dtstart, past_dtend]].each do |dtstart, dtend|
          guest = User.create(
            name: Faker::Name.name,
            email: Faker::Internet.email,
            phone: Faker::PhoneNumber.cell_phone
          )
          booking = Booking.create(
            house: house,
            room: room,
            summary: Faker::GameOfThrones.character,
            description: Faker::Lorem.paragraph,
            status: :confirmed,
            user: guest,
            dtstart: dtstart,
            dtend: dtend
          )
        end
      end
    end
  end
```

### I need a function to generate each room's each date's availability
```
  room = house.rooms.first
  room.availability_between_dates(Date.today, Date.today + 10.days)
```
   I need it to return following
```
{
   "total_rooms": 10,
   "start_date": "2019-10-18",
   "end_date": "2020-10-27",
   "payload": [
     {
       "date":  "2019-10-18",
       "allotment": 1
     },
     {
       "date":  "2019-10-19",
       "allotment": 2
     },
     {
       "date":  "2019-10-20",
       "allotment": 3
     },
     ...
   ]
```

### You need to probably loop over all the existing Booking to determine whether each date has how many room unit left. 
* Assuming if you have following bookings

```
house = House.first
room = house.rooms.first
booking1 = Booking.new(
  dtstart: "2019-10-11",
  dtend: "2019-10-12"
  house: house,
  room: room
)
booking2 = Booking.new(
  dtstart: "2019-10-13",
  dtend: "2019-10-14"
  house: house,
  room: room
)
booking2 = Booking.new(
  dtstart: "2019-10-16",
  dtend: "2019-10-20"
  house: house,
  room: room
)

room.availability_between_dates("2019-10-11", "2019-10-20")


```
* return following
```
{
  "total_rooms": 10,
  "start_date": "2019-10-11",
  "end_date": "2020-10-20",
  "payload": [
    {
      "date":  "2019-10-11",
      "allotment": 9
    },
    {
      "date":  "2019-10-12",
      "allotment": 10
    },
    {
      "date":  "2019-10-13",
      "allotment": 9
    },
    {
      "date":  "2019-10-14",
      "allotment": 10
    },
    {
      "date":  "2019-10-15",
      "allotment": 10
    },
    {
      "date":  "2019-10-16",
      "allotment": 9
    },
    {
      "date":  "2019-10-17",
      "allotment": 9
    },
    {
      "date":  "2019-10-18",
      "allotment": 9
    },
    {
      "date":  "2019-10-19",
      "allotment": 9
    },
    {
      "date":  "2019-10-20",
      "allotment": 10
    }
  ]
```   
