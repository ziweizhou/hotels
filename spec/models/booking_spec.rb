# frozen_string_literal: true

require 'rails_helper'
require 'date'

RSpec.describe Booking, type: :model do
  before(:each) do
    # DatabaseCleaner.clean
  end

  context '#create' do
    it 'should block connected room units' do
      # Arrange
      house = House.create!(name: Faker::GameOfThrones.character)
      guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
      type_loren = house.room_types.create!(name: 'Lorent Lorch')
      type_ocean = house.room_types.create!(name: 'Ocean View')

      unit_0001 = Unit.create!(room_no: 0001, house: house)
      unit_0002 = Unit.create!(room_no: 0002, house: house)

      room_loren = house.rooms.create!(name: 'Lorent Lorch 101', room_type: type_loren)
      RoomUnit.create!(room: room_loren, house: house , unit: unit_0001)
      RoomUnit.create!(room: room_loren, house: house , unit: unit_0002)

      room_ocean = house.rooms.create!(name: 'Ocean View 201', room_type: type_ocean)
      RoomUnit.create!(room: room_ocean, house: house, unit: unit_0001)


      room_ocean = house.rooms.create!(name: 'Ocean View 202', room_type: type_ocean)
      RoomUnit.create!(room: room_ocean, house: house, unit: unit_0002)

      #    "Lorent Lorch 101"               "Ocean View 201"          "Ocean View 202"
      #       /       \                             |                      |
      #    0001       0002                         0001                   0002


      # Act
      Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room_type: type_loren, user: guest) # Book "Lorent Lorch 101"

      # Assert
      bookings = Booking.all
      expect(bookings.count).to eql(1)


    end

    it 'should NOT block non connected units' do
      # Arrange
      house = House.create!(name: Faker::GameOfThrones.character)
      guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
      room = house.rooms.create!(name: Faker::GameOfThrones.character)

      #          C
      #       /     \
      #     A        B

      unitC = room.room_units.create!(room_no: Faker::Number.number(4), house: house, virtual: true)
      unitA = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
      unitB = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)

      # Act
      Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitA, user: guest) # Book A

      # Assert
      bookings = Booking.all
      expect(bookings.count).to eql(1)
      expect(bookings[0].status).to eql('confirmed')
    end

    it 'should create overlap bookings when an existing booking exists' do
      # Arrange
      house = House.create!(name: Faker::GameOfThrones.character)
      guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
      room = house.rooms.create!(name: Faker::GameOfThrones.character)

      #          C
      #       /     \
      #     A        B

      unitC = room.room_units.create!(room_no: Faker::Number.number(4), house: house, virtual: true)
      unitA = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
      unitB = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)


      Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitC, user: guest) # Book C, Block A and B

      # Act
      Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitC, user: guest) # Book C, Block A and B

      # Assert
      bookings = Booking.all.to_a
      expect(bookings.count).to eql(6)
      expect(bookings.select{ |r| r.room_unit_id == unitA.id && r.status == 'overlap'}.count).to eql(1)
      expect(bookings.select{ |r| r.room_unit_id == unitB.id && r.status == 'overlap'}.count).to eql(1)
      expect(bookings.select{ |r| r.room_unit_id == unitC.id && r.status == 'overlap'}.count).to eql(1)
    end

    it 'creates overlap booking when child rooms are not available' do
      # Arrange
      house = House.create!(name: Faker::GameOfThrones.character)
      guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
      room = house.rooms.create!(name: Faker::GameOfThrones.character)

      #          C
      #       /     \
      #     A        B

      unitC = room.room_units.create!(room_no: Faker::Number.number(4), house: house, virtual: true)
      unitA = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
      unitB = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)

      Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitA, user: guest) # A

      # Act
      Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitC, user: guest) # Try to book C

      # Assert
      bookings = Booking.all.to_a
      expect(bookings.count).to eql(4)
      expect(bookings.select{ |r| r.room_unit_id == unitA.id && r.status == 'overlap'}.count).to eql(1)
      expect(bookings.select{ |r| r.room_unit_id == unitB.id && r.status == 'overlap'}.count).to eql(1)
      expect(bookings.select{ |r| r.room_unit_id == unitC.id && r.status == 'overlap'}.count).to eql(1)
    end
  end

  context '#update' do
    it 'mark as cancel' do
      # Arrange
      house = House.create!(name: Faker::GameOfThrones.character)
      guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
      room = house.rooms.create!(name: Faker::GameOfThrones.character)

      #          C
      #       /     \
      #     A        B

      unitC = room.room_units.create!(room_no: Faker::Number.number(4), house: house, virtual: true)
      unitA = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
      unitB = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
      booking = Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitC, user: guest) # Book C, Block A and B

      # Act
      booking.update(status: :cancelled)

      # Assert
      bookings = Booking.all
      expect(bookings.count).to eql(3)
      expect(bookings.find{ |r| r.room_unit_id == unitA.id }.status).to eql('cancelled')
      expect(bookings.find{ |r| r.room_unit_id == unitB.id }.status).to eql('cancelled')
      expect(bookings.find{ |r| r.room_unit_id == unitC.id }.status).to eql('cancelled')
    end

    it 'reschedule dates' do
      # Arrange
      house = House.create!(name: Faker::GameOfThrones.character)
      guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
      room = house.rooms.create!(name: Faker::GameOfThrones.character)

      #          C
      #       /     \
      #     A        B

      unitC = room.room_units.create!(room_no: Faker::Number.number(4), house: house, virtual: true)
      unitA = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
      unitB = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
      booking = Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitC, user: guest) # Book C, Block A and B

      # Act
      booking.update(dtstart: "2019-10-12", dtend: "2019-10-13")

      # Assert
      bookings = Booking.all
      expect(bookings.count).to eql(3)
      expect(bookings.find{ |r| r.room_unit_id == unitA.id && r.parent_booking_id == booking.id }.to_json)
          .to include_json({status: 'blocked', dtstart: '2019-10-12', dtend: '2019-10-13'})
      expect(bookings.find{ |r| r.room_unit_id == unitB.id && r.parent_booking_id == booking.id }.to_json)
          .to include_json({status: 'blocked', dtstart: '2019-10-12', dtend: '2019-10-13'})
      expect(bookings.find{ |r| r.room_unit_id == unitC.id && r.id == booking.id }.to_json)
          .to include_json({status: 'confirmed',dtstart: '2019-10-12', dtend: '2019-10-13'})
    end

    it 'throws error when reschedule dates are not available' do
      # Arrange
      house = House.create!(name: Faker::GameOfThrones.character)
      guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
      room = house.rooms.create!(name: Faker::GameOfThrones.character)

      #          C
      #       /     \
      #     A        B

      unitC = room.room_units.create!(room_no: Faker::Number.number(4), house: house, virtual: true)
      unitA = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
      unitB = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
      booking = Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitC, user: guest) # Book C, Block A and B
      Booking.create!(dtstart: "2019-10-12", dtend: "2019-10-13", house: house, room: room, room_unit: unitC, user: guest) # Book C, Block A and B

      # Act
      expect { booking.update(dtstart: "2019-10-12", dtend: "2019-10-13") }.to raise_error("Dates not available")

      # Assert
      bookings = Booking.all
      expect(bookings.count).to eql(6)
      expect(bookings.find{ |r| r.room_unit_id == unitA.id && r.parent_booking_id == booking.id }.status).to eql('blocked')
      expect(bookings.find{ |r| r.room_unit_id == unitB.id && r.parent_booking_id == booking.id }.status).to eql('blocked')
      expect(bookings.find{ |r| r.room_unit_id == unitC.id && r.id == booking.id }.status).to eql('confirmed')
    end
  end

  context '#destroy' do
    it 'should destroy connected booking' do
      # Arrange
      house = House.create!(name: Faker::GameOfThrones.character)
      guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
      room = house.rooms.create!(name: Faker::GameOfThrones.character)

      #          C
      #       /     \
      #     A        B

      unitC = room.room_units.create!(room_no: Faker::Number.number(4), house: house, virtual: true)
      unitA = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
      unitB = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
      booking = Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitC, user: guest) # Book C, Block A and B
      bookings_before_destroy = Booking.all.to_a

      # Act
      booking.destroy

      # Assert
      bookings_after_destroy = Booking.all.to_a
      expect(bookings_before_destroy.count).to eql(3)
      expect(bookings_after_destroy.count).to eql(0)
    end

    it 'should NOT destroy non connected bookings' do
      # Arrange
      house = House.create!(name: Faker::GameOfThrones.character)
      guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
      room = house.rooms.create!(name: Faker::GameOfThrones.character)

      #          C
      #       /     \
      #     A        B

      unitC = room.room_units.create!(room_no: Faker::Number.number(4), house: house, virtual: true)
      unitA = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
      unitB = room.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
      booking = Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitA, user: guest) # Book A
      booking = Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitB, user: guest) # Book A
      bookings_before_destroy = Booking.all.to_a

      # Act
      booking.destroy

      # Assert
      bookings_after_destroy = Booking.all.to_a
      expect(bookings_before_destroy.count).to eql(2)
      expect(bookings_after_destroy.count).to eql(1)
    end
  end
end
