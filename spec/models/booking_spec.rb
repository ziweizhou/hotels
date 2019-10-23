# frozen_string_literal: true

require 'rails_helper'
require 'date'

RSpec.describe Booking, type: :model do
  before(:each) do
    DatabaseCleaner.clean
  end
  it 'should block connected room units while a booking a virtual unit' do
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

  it 'should NOT block additional room units while booking a NON virtual unit' do
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
    Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: unitA, user: guest) # Book C, Block A and B

    # Assert
    bookings = Booking.all
    expect(bookings.count).to eql(1)
    expect(bookings[0].status).to eql('confirmed')
  end
end
