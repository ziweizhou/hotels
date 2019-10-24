# frozen_string_literal: true

require 'rails_helper'
require 'date'

RSpec.describe Booking, type: :model do
  before(:each) do
    DatabaseCleaner.clean
  end

  context '#create' do
    it 'should block connected room units' do
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
      Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitC, user: guest) # Book C, Block A and B

      # Assert
      bookings = Booking.all
      expect(bookings.count).to eql(3)
      expect(bookings.find{ |r| r.room_unit_id == unitA.id }.status).to eql('blocked')
      expect(bookings.find{ |r| r.room_unit_id == unitB.id }.status).to eql('blocked')
      expect(bookings.find{ |r| r.room_unit_id == unitC.id }.status).to eql('confirmed')
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
