# frozen_string_literal: true

require 'rails_helper'
require 'date'

RSpec.describe Booking, type: :model do
  before(:each) do
    DatabaseCleaner.clean
  end

  context '#create' do
    test_cases = [
        {
            title: 'Creates bookings when available',
            rooms: [
                { type: 'Pond', name: 'Pond 1', units: [5, 6, 7] },
                { type: 'Lorent Lorch', name: 'Lorent Lorch 1', units: [1, 2] },
                { type: 'Lorent Lorch', name: 'Lorent Lorch 2', units: [3, 4] },
                { type: 'River', name: 'River 1', units: [4, 5] },
                { type: 'River', name: 'River 2', units: [6, 7] },
                { type: 'Ocean View', name: 'Ocean View 1', units: [1] },
                { type: 'Ocean View', name: 'Ocean View 2', units: [2] },
                { type: 'Ocean View', name: 'Ocean View 3', units: [3] }
            ],
            bookings: [
                { dtstart: '2019-10-01', dtend: '2019-10-01', room_type: 'Ocean View' },
                { dtstart: '2019-10-01', dtend: '2019-10-01', room_type: 'River' },
                { dtstart: '2019-10-01', dtend: '2019-10-01', room_type: 'Lorent Lorch' }
            ],
            expect: {
                booking_count: 3,
                booking_types: ['Ocean View', 'River', 'Lorent Lorch']
            }
        }
    ]
    test_cases.each do |test_case|
      it (test_case[:title]).to_s do
        # Arrange
        house = House.create!(name: Faker::GameOfThrones.character)
        guest = User.create(name: Faker::Name.name, email: Faker::Internet.email, phone: Faker::PhoneNumber.cell_phone)
        room_types = {}
        units = {}
        rooms = {}
        test_case[:rooms].each do |room|
          unless room_types[room[:type]]
            room_types[room[:type]] = house.room_types.create!(name: room[:type])
          end

          created_room = house.rooms.create!(name: room[:name], room_type: room_types[room[:type]])
          room[:units].each do |unit|
            unless units[unit]
              units[unit] = Unit.create!(room_no: unit, house: house)
            end
            RoomUnit.create!(room: created_room, house: house, unit: units[unit])
          end
        end

        # Act
        test_case[:bookings].each do |booking|
          Booking.create!(dtstart: booking[:dtstart], dtend: booking[:dtend], house: house, room_type: room_types[booking[:room_type]], user: guest)
        end

        # Assert
        allocations = Booking.new.get_virtual_slots
        bookings = Booking.all
        expect(allocations.count).to eql(test_case[:expect][:booking_count])
        expect(bookings.count).to eql(test_case[:expect][:booking_count])
        expect(allocations.map{|r| r[:room][:room_type]}).to include(*test_case[:expect][:booking_types])
      end
    end

    # it 'should create' do
    #   house = House.create!(name: Faker::GameOfThrones.character)
    #   guest = User.create(name: Faker::Name.name, email: Faker::Internet.email, phone: Faker::PhoneNumber.cell_phone)
    #   type_loren = house.room_types.create!(name: 'Lorent Lorch')
    #   type_ocean = house.room_types.create!(name: 'Ocean View')
    #   type_river = house.room_types.create!(name: 'River')
    #   type_pond = house.room_types.create!(name: 'Pond')
    # 
    #   unit_0001 = Unit.create!(room_no: 0o001, house: house)
    #   unit_0002 = Unit.create!(room_no: 0o002, house: house)
    #   unit_0003 = Unit.create!(room_no: 0o003, house: house)
    #   unit_0004 = Unit.create!(room_no: 0o004, house: house)
    #   unit_0005 = Unit.create!(room_no: 0o005, house: house)
    #   unit_0006 = Unit.create!(room_no: 0o006, house: house)
    #   unit_0007 = Unit.create!(room_no: 0o007, house: house)
    # 
    #   room_loren_1 = house.rooms.create!(name: 'Lorent Lorch 1', room_type: type_loren)
    #   RoomUnit.create!(room: room_loren_1, house: house, unit: unit_0001)
    #   RoomUnit.create!(room: room_loren_1, house: house, unit: unit_0002)
    # 
    #   room_loren_2 = house.rooms.create!(name: 'Lorent Lorch 2', room_type: type_loren)
    #   RoomUnit.create!(room: room_loren_2, house: house, unit: unit_0003)
    #   RoomUnit.create!(room: room_loren_2, house: house, unit: unit_0004)
    # 
    #   room_pond_1 = house.rooms.create!(name: 'Pond 1', room_type: type_pond)
    #   RoomUnit.create!(room: room_pond_1, house: house, unit: unit_0005)
    #   RoomUnit.create!(room: room_pond_1, house: house, unit: unit_0006)
    #   RoomUnit.create!(room: room_pond_1, house: house, unit: unit_0007)
    # 
    #   room_ocean_1 = house.rooms.create!(name: 'Ocean View 1', room_type: type_ocean)
    #   RoomUnit.create!(room: room_ocean_1, house: house, unit: unit_0001)
    # 
    #   room_ocean_2 = house.rooms.create!(name: 'Ocean View 2', room_type: type_ocean)
    #   RoomUnit.create!(room: room_ocean_2, house: house, unit: unit_0002)
    # 
    #   room_ocean_3 = house.rooms.create!(name: 'Ocean View 3', room_type: type_ocean)
    #   RoomUnit.create!(room: room_ocean_3, house: house, unit: unit_0003)
    # 
    #   room_river_1 = house.rooms.create!(name: 'River 1', room_type: type_river)
    #   RoomUnit.create!(room: room_river_1, house: house, unit: unit_0004)
    #   RoomUnit.create!(room: room_river_1, house: house, unit: unit_0005)
    # 
    #   room_river_2 = house.rooms.create!(name: 'River 2', room_type: type_river)
    #   RoomUnit.create!(room: room_river_2, house: house, unit: unit_0006)
    #   RoomUnit.create!(room: room_river_2, house: house, unit: unit_0007)
    # 
    #   # ╔═══╦════════════════╦══════════════╗
    #   # ║ 1 ║                ║ Ocean View 1 ║
    #   # ╠═══╣ Lorent Lorch 1 ╠══════════════╣
    #   # ║ 2 ║                ║ Ocean View 2 ║
    #   # ╠═══╬════════════════╬══════════════╣
    #   # ║ 3 ║ Lorent Lorch 2 ║ Ocean View 3 ║
    #   # ╠═══╣                ╠══════════════╣
    #   # ║ 4 ║                ║ River 1      ║
    #   # ╠═══╬════════════════╣              ║
    #   # ║ 5 ║ Pond 1         ║              ║
    #   # ╠═══╣                ╠══════════════╣
    #   # ║ 6 ║                ║ River 2      ║
    #   # ╠═══╣                ║              ║
    #   # ║ 7 ║                ║              ║
    #   # ╚═══╩════════════════╩══════════════╝
    # 
    #   # Act
    #   Booking.create!(dtstart: '2019-10-01', dtend: '2019-10-01', house: house, room_type: type_ocean, user: guest) # Book "Ocean View"
    #   Booking.create!(dtstart: '2019-10-01', dtend: '2019-10-01', house: house, room_type: type_river, user: guest) # Book "River"
    #   Booking.create!(dtstart: '2019-10-01', dtend: '2019-10-01', house: house, room_type: type_loren, user: guest) # Book "Lorent Lorch"
    # 
    #   # ╔═══╦════════════════════╦══════════════════╗
    #   # ║ 1 ║                    ║ Ocean View 1     ║
    #   # ╠═══╣ **Lorent Lorch 1** ╠══════════════════╣
    #   # ║ 2 ║                    ║ Ocean View 2     ║
    #   # ╠═══╬════════════════════╬══════════════════╣
    #   # ║ 3 ║ Lorent Lorch 2     ║ **Ocean View 3** ║
    #   # ╠═══╣                    ╠══════════════════╣
    #   # ║ 4 ║                    ║ **River 1**      ║
    #   # ╠═══╬════════════════════╣                  ║
    #   # ║ 5 ║ Pond 1             ║                  ║
    #   # ╠═══╣                    ╠══════════════════╣
    #   # ║ 6 ║                    ║ River 2          ║
    #   # ╠═══╣                    ║                  ║
    #   # ║ 7 ║                    ║                  ║
    #   # ╚═══╩════════════════════╩══════════════════╝
    # 
    #   # Assert
    #   allocations = Booking.new.get_virtual_slots
    #   puts allocations
    #   expect(Booking.count).to eql(3)
    # end
  end
  #
  # context '#create' do
  #   it 'should block connected room units' do
  #     # Arrange
  #     house = House.create!(name: Faker::GameOfThrones.character)
  #     guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
  #     type_loren = house.room_types.create!(name: 'Lorent Lorch')
  #     type_ocean = house.room_types.create!(name: 'Ocean View')
  #
  #     unit_0001 = Unit.create!(room_no: 0001, house: house)
  #     unit_0002 = Unit.create!(room_no: 0002, house: house)
  #
  #     room_loren = house.rooms.create!(name: 'Lorent Lorch 101', room_type: type_loren)
  #     RoomUnit.create!(room: room_loren, house: house , unit: unit_0001)
  #     RoomUnit.create!(room: room_loren, house: house , unit: unit_0002)
  #
  #     room_ocean = house.rooms.create!(name: 'Ocean View 201', room_type: type_ocean)
  #     RoomUnit.create!(room: room_ocean, house: house, unit: unit_0001)
  #
  #
  #     room_ocean = house.rooms.create!(name: 'Ocean View 202', room_type: type_ocean)
  #     RoomUnit.create!(room: room_ocean, house: house, unit: unit_0002)
  #
  #     #    "Lorent Lorch 101"               "Ocean View 201"          "Ocean View 202"
  #     #       /       \                             |                      |
  #     #    0001       0002                         0001                   0002
  #
  #
  #     # Act
  #     Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room_type: type_loren, user: guest) # Book "Lorent Lorch 101"
  #
  #     # Assert
  #     bookings = Booking.all
  #     expect(bookings.count).to eql(1)
  #
  #
  #   end
  #
  #   it 'should NOT block non connected units' do
  #     # Arrange
  #     house = House.create!(name: Faker::GameOfThrones.character)
  #     guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
  #     room = house.rooms.create!(name: Faker::GameOfThrones.character)
  #
  #     #          C
  #     #       /     \
  #     #     A        B
  #
  #     unitC = room.room_units.create!(room_no: Faker::Number.number(4), house: house, virtual: true)
  #     unitA = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
  #     unitB = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
  #
  #     # Act
  #     Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitA, user: guest) # Book A
  #
  #     # Assert
  #     bookings = Booking.all
  #     expect(bookings.count).to eql(1)
  #     expect(bookings[0].status).to eql('confirmed')
  #   end
  #
  #   it 'should create overlap bookings when an existing booking exists' do
  #     # Arrange
  #     house = House.create!(name: Faker::GameOfThrones.character)
  #     guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
  #     room = house.rooms.create!(name: Faker::GameOfThrones.character)
  #
  #     #          C
  #     #       /     \
  #     #     A        B
  #
  #     unitC = room.room_units.create!(room_no: Faker::Number.number(4), house: house, virtual: true)
  #     unitA = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
  #     unitB = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
  #
  #
  #     Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitC, user: guest) # Book C, Block A and B
  #
  #     # Act
  #     Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitC, user: guest) # Book C, Block A and B
  #
  #     # Assert
  #     bookings = Booking.all.to_a
  #     expect(bookings.count).to eql(6)
  #     expect(bookings.select{ |r| r.room_unit_id == unitA.id && r.status == 'overlap'}.count).to eql(1)
  #     expect(bookings.select{ |r| r.room_unit_id == unitB.id && r.status == 'overlap'}.count).to eql(1)
  #     expect(bookings.select{ |r| r.room_unit_id == unitC.id && r.status == 'overlap'}.count).to eql(1)
  #   end
  #
  #   it 'creates overlap booking when child rooms are not available' do
  #     # Arrange
  #     house = House.create!(name: Faker::GameOfThrones.character)
  #     guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
  #     room = house.rooms.create!(name: Faker::GameOfThrones.character)
  #
  #     #          C
  #     #       /     \
  #     #     A        B
  #
  #     unitC = room.room_units.create!(room_no: Faker::Number.number(4), house: house, virtual: true)
  #     unitA = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
  #     unitB = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
  #
  #     Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitA, user: guest) # A
  #
  #     # Act
  #     Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitC, user: guest) # Try to book C
  #
  #     # Assert
  #     bookings = Booking.all.to_a
  #     expect(bookings.count).to eql(4)
  #     expect(bookings.select{ |r| r.room_unit_id == unitA.id && r.status == 'overlap'}.count).to eql(1)
  #     expect(bookings.select{ |r| r.room_unit_id == unitB.id && r.status == 'overlap'}.count).to eql(1)
  #     expect(bookings.select{ |r| r.room_unit_id == unitC.id && r.status == 'overlap'}.count).to eql(1)
  #   end
  # end
  #
  # context '#update' do
  #   it 'mark as cancel' do
  #     # Arrange
  #     house = House.create!(name: Faker::GameOfThrones.character)
  #     guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
  #     room = house.rooms.create!(name: Faker::GameOfThrones.character)
  #
  #     #          C
  #     #       /     \
  #     #     A        B
  #
  #     unitC = room.room_units.create!(room_no: Faker::Number.number(4), house: house, virtual: true)
  #     unitA = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
  #     unitB = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
  #     booking = Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitC, user: guest) # Book C, Block A and B
  #
  #     # Act
  #     booking.update(status: :cancelled)
  #
  #     # Assert
  #     bookings = Booking.all
  #     expect(bookings.count).to eql(3)
  #     expect(bookings.find{ |r| r.room_unit_id == unitA.id }.status).to eql('cancelled')
  #     expect(bookings.find{ |r| r.room_unit_id == unitB.id }.status).to eql('cancelled')
  #     expect(bookings.find{ |r| r.room_unit_id == unitC.id }.status).to eql('cancelled')
  #   end
  #
  #   it 'reschedule dates' do
  #     # Arrange
  #     house = House.create!(name: Faker::GameOfThrones.character)
  #     guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
  #     room = house.rooms.create!(name: Faker::GameOfThrones.character)
  #
  #     #          C
  #     #       /     \
  #     #     A        B
  #
  #     unitC = room.room_units.create!(room_no: Faker::Number.number(4), house: house, virtual: true)
  #     unitA = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
  #     unitB = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
  #     booking = Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitC, user: guest) # Book C, Block A and B
  #
  #     # Act
  #     booking.update(dtstart: "2019-10-12", dtend: "2019-10-13")
  #
  #     # Assert
  #     bookings = Booking.all
  #     expect(bookings.count).to eql(3)
  #     expect(bookings.find{ |r| r.room_unit_id == unitA.id && r.parent_booking_id == booking.id }.to_json)
  #         .to include_json({status: 'blocked', dtstart: '2019-10-12', dtend: '2019-10-13'})
  #     expect(bookings.find{ |r| r.room_unit_id == unitB.id && r.parent_booking_id == booking.id }.to_json)
  #         .to include_json({status: 'blocked', dtstart: '2019-10-12', dtend: '2019-10-13'})
  #     expect(bookings.find{ |r| r.room_unit_id == unitC.id && r.id == booking.id }.to_json)
  #         .to include_json({status: 'confirmed',dtstart: '2019-10-12', dtend: '2019-10-13'})
  #   end
  #
  #   it 'throws error when reschedule dates are not available' do
  #     # Arrange
  #     house = House.create!(name: Faker::GameOfThrones.character)
  #     guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
  #     room = house.rooms.create!(name: Faker::GameOfThrones.character)
  #
  #     #          C
  #     #       /     \
  #     #     A        B
  #
  #     unitC = room.room_units.create!(room_no: Faker::Number.number(4), house: house, virtual: true)
  #     unitA = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
  #     unitB = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
  #     booking = Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitC, user: guest) # Book C, Block A and B
  #     Booking.create!(dtstart: "2019-10-12", dtend: "2019-10-13", house: house, room: room, room_unit: unitC, user: guest) # Book C, Block A and B
  #
  #     # Act
  #     expect { booking.update(dtstart: "2019-10-12", dtend: "2019-10-13") }.to raise_error("Dates not available")
  #
  #     # Assert
  #     bookings = Booking.all
  #     expect(bookings.count).to eql(6)
  #     expect(bookings.find{ |r| r.room_unit_id == unitA.id && r.parent_booking_id == booking.id }.status).to eql('blocked')
  #     expect(bookings.find{ |r| r.room_unit_id == unitB.id && r.parent_booking_id == booking.id }.status).to eql('blocked')
  #     expect(bookings.find{ |r| r.room_unit_id == unitC.id && r.id == booking.id }.status).to eql('confirmed')
  #   end
  # end
  #
  # context '#destroy' do
  #   it 'should destroy connected booking' do
  #     # Arrange
  #     house = House.create!(name: Faker::GameOfThrones.character)
  #     guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
  #     room = house.rooms.create!(name: Faker::GameOfThrones.character)
  #
  #     #          C
  #     #       /     \
  #     #     A        B
  #
  #     unitC = room.room_units.create!(room_no: Faker::Number.number(4), house: house, virtual: true)
  #     unitA = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
  #     unitB = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
  #     booking = Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitC, user: guest) # Book C, Block A and B
  #     bookings_before_destroy = Booking.all.to_a
  #
  #     # Act
  #     booking.destroy
  #
  #     # Assert
  #     bookings_after_destroy = Booking.all.to_a
  #     expect(bookings_before_destroy.count).to eql(3)
  #     expect(bookings_after_destroy.count).to eql(0)
  #   end
  #
  #   it 'should NOT destroy non connected bookings' do
  #     # Arrange
  #     house = House.create!(name: Faker::GameOfThrones.character)
  #     guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
  #     room = house.rooms.create!(name: Faker::GameOfThrones.character)
  #
  #     #          C
  #     #       /     \
  #     #     A        B
  #
  #     unitC = room.room_units.create!(room_no: Faker::Number.number(4), house: house, virtual: true)
  #     unitA = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
  #     unitB = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
  #     booking = Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitA, user: guest) # Book A
  #     booking = Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitB, user: guest) # Book A
  #     bookings_before_destroy = Booking.all.to_a
  #
  #     # Act
  #     booking.destroy
  #
  #     # Assert
  #     bookings_after_destroy = Booking.all.to_a
  #     expect(bookings_before_destroy.count).to eql(2)
  #     expect(bookings_after_destroy.count).to eql(1)
  #   end
  # end
end
