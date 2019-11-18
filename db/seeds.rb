# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#

puts 'create houses'

Booking.destroy_all
User.destroy_all
RoomUnit.destroy_all
Room.destroy_all
Unit.destroy_all
RoomType.destroy_all
House.destroy_all

house = House.create!(name: Faker::GameOfThrones.character)
guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
type_loren = house.room_types.create!(name: 'Lorent Lorch')
type_ocean = house.room_types.create!(name: 'Ocean View')
type_river = house.room_types.create!(name: 'River')
type_pond = house.room_types.create!(name: 'Pond')

unit_0001 = Unit.create!(room_no: 0001, house: house)
unit_0002 = Unit.create!(room_no: 0002, house: house)
unit_0003 = Unit.create!(room_no: 0003, house: house)
unit_0004 = Unit.create!(room_no: 0004, house: house)
unit_0005 = Unit.create!(room_no: 0005, house: house)
unit_0006 = Unit.create!(room_no: 0006, house: house)
unit_0007 = Unit.create!(room_no: 0007, house: house)

room_loren_1 = house.rooms.create!(name: 'Lorent Lorch 1', room_type: type_loren)
RoomUnit.create!(room: room_loren_1, house: house , unit: unit_0001)
RoomUnit.create!(room: room_loren_1, house: house , unit: unit_0002)

room_loren_2 = house.rooms.create!(name: 'Lorent Lorch 2', room_type: type_loren)
RoomUnit.create!(room: room_loren_2, house: house , unit: unit_0003)
RoomUnit.create!(room: room_loren_2, house: house , unit: unit_0004)

room_pond_1 = house.rooms.create!(name: 'Pond 1', room_type: type_pond)
RoomUnit.create!(room: room_pond_1, house: house , unit: unit_0005)
RoomUnit.create!(room: room_pond_1, house: house , unit: unit_0006)
RoomUnit.create!(room: room_pond_1, house: house , unit: unit_0007)

room_ocean_1 = house.rooms.create!(name: 'Ocean View 1', room_type: type_ocean)
RoomUnit.create!(room: room_ocean_1, house: house, unit: unit_0001)

room_ocean_2 = house.rooms.create!(name: 'Ocean View 2', room_type: type_ocean)
RoomUnit.create!(room: room_ocean_2, house: house, unit: unit_0002)

room_ocean_3 = house.rooms.create!(name: 'Ocean View 3', room_type: type_ocean)
RoomUnit.create!(room: room_ocean_3, house: house, unit: unit_0003)

room_river_1 = house.rooms.create!(name: 'River 1', room_type: type_river)
RoomUnit.create!(room: room_river_1, house: house, unit: unit_0004)
RoomUnit.create!(room: room_river_1, house: house, unit: unit_0005)

room_river_2 = house.rooms.create!(name: 'River 2', room_type: type_river)
RoomUnit.create!(room: room_river_2, house: house, unit: unit_0006)
RoomUnit.create!(room: room_river_2, house: house, unit: unit_0007)

# ╔═══╦════════════════╦══════════════╗
# ║ 1 ║                ║ Ocean View 1 ║
# ╠═══╣ Lorent Lorch 1 ╠══════════════╣
# ║ 2 ║                ║ Ocean View 2 ║
# ╠═══╬════════════════╬══════════════╣
# ║ 3 ║ Lorent Lorch 2 ║ Ocean View 3 ║
# ╠═══╣                ╠══════════════╣
# ║ 4 ║                ║ River 1      ║
# ╠═══╬════════════════╣              ║
# ║ 5 ║ Pond 1         ║              ║
# ╠═══╣                ╠══════════════╣
# ║ 6 ║                ║ River 2      ║
# ╠═══╣                ║              ║
# ║ 7 ║                ║              ║
# ╚═══╩════════════════╩══════════════╝

# Act
Booking.create!(dtstart: "2019-10-01", dtend: "2019-10-01", house: house, room_type: type_ocean, user: guest) # Book "Ocean View"
Booking.create!(dtstart: "2019-10-01", dtend: "2019-10-01", house: house, room_type: type_river, user: guest) # Book "River"
Booking.create!(dtstart: "2019-10-01", dtend: "2019-10-01", house: house, room_type: type_loren, user: guest) # Book "Lorent Lorch"

# ╔═══╦════════════════════╦══════════════════╗
# ║ 1 ║                    ║ Ocean View 1     ║
# ╠═══╣ **Lorent Lorch 1** ╠══════════════════╣
# ║ 2 ║                    ║ Ocean View 2     ║
# ╠═══╬════════════════════╬══════════════════╣
# ║ 3 ║ Lorent Lorch 2     ║ **Ocean View 3** ║
# ╠═══╣                    ╠══════════════════╣
# ║ 4 ║                    ║ **River 1**      ║
# ╠═══╬════════════════════╣                  ║
# ║ 5 ║ Pond 1             ║                  ║
# ╠═══╣                    ╠══════════════════╣
# ║ 6 ║                    ║ River 2          ║
# ╠═══╣                    ║                  ║
# ║ 7 ║                    ║                  ║
# ╚═══╩════════════════════╩══════════════════╝

# Print virtual allocations
