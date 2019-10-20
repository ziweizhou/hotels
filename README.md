# hotels
Assuming you have following data structure 
![ERD Diagram](https://raw.githubusercontent.com/ziweizhou/hotels/master/house_erd.png)


### You run these mockup to build the seed data
```ruby
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
```ruby
  room = house.rooms.first
  room.availability_between_dates(Date.today, Date.today + 10.days)
```
   I need it to return following
```json
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

```ruby
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
```json
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

# Step 2. Connected Room
1. Add this change to room_unit.rb
```ruby
  belongs_to :part_of_room, class_name: 'RoomUnit'
  has_many :consist_of_rooms, class_name: 'RoomUnit', foreign_key: :part_of_room_id
```
and DB Migration
```ruby
class AddComposedOfToRoomUnits < ActiveRecord::Migration[5.2]
  def change
    add_column :room_units, :part_of_room_id, :integer
  end
end
```
2. Concept of connected room
Room A and B are next each other and can be connected. 
Some Hotel have A, B and C (A + B).  So 
- Either A or B got booked, C needs to be blocked.
- If C got booked, A and B needs to be blocked. 

3. Sample Code
```ruby
family_room = Room.new(name:"Family Room Style")
connected_unit = RoomUnit.create(room_no:"A+B", room: family_room)

unit1 = RoomUnit.first
unit2 = RoomUnit.second

unit1.part_of_room = connected_unit
unit2.part_of_room = connected_unit

unit1.save
unit2.save
```
4. If there is a booking for RoomUnit1 and assuming `connected_unit.room.room_units.size == 10`

```ruby
house = House.first
booking1 = Booking.new(
  dtstart: "2019-10-11",
  dtend: "2019-10-12"
  house: house,
  room: unit1.room,
  room_unit: unit1
)

family_room.availability_between_dates("2019-10-11", "2019-10-12")
```

* return following

```json
{
  "total_rooms": 10,
  "start_date": "2019-10-11",
  "end_date": "2020-10-12",
  "payload": [
    {
      "date":  "2019-10-11",
      "allotment": 9
    },
    {
      "date":  "2019-10-12",
      "allotment": 10
    }
  ]
```  
5. If there is a booking for **connected_unit** and assuming unit1 and unit2 belongs to the different room and `room.room_units.size == 1` for both unit1 and unit2's room

```ruby
house = House.first
booking1 = Booking.new(
  dtstart: "2019-10-11",
  dtend: "2019-10-12"
  house: house,
  room: connected_unit.room,
  room_unit: connected_unit
)

unit1.room.availability_between_dates("2019-10-11", "2019-10-12")
```
* return following
```json
{
  "total_rooms": 1,
  "start_date": "2019-10-11",
  "end_date": "2020-10-12",
  "payload": [
    {
      "date":  "2019-10-11",
      "allotment": 0
    },
    {
      "date":  "2019-10-12",
      "allotment": 1
    }
  ]
```
** for unit2 ** 
```
unit2.room.availability_between_dates("2019-10-11", "2019-10-12")
```
* return following
```json
{
  "total_rooms": 1,
  "start_date": "2019-10-11",
  "end_date": "2020-10-12",
  "payload": [
    {
      "date":  "2019-10-11",
      "allotment": 0
    },
    {
      "date":  "2019-10-12",
      "allotment": 1
    }
  ]
```  
