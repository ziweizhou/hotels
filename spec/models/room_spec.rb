# frozen_string_literal: true

require 'rails_helper'
require 'date'

RSpec.describe Room, type: :model do
  before(:each) do
    DatabaseCleaner.clean
  end
  context '#availability_between_dates' do
    it 'with single room' do
      # Arrange
      house = House.create!(name: Faker::GameOfThrones.character)
      guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
      room = house.rooms.create!(name: Faker::GameOfThrones.character)
      room_units = []
      10.times.each do
        room_units << room.room_units.create!(room_no: Faker::Number.number(4), house: house)
      end
      Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, room_unit: room_units.sample, user: guest)
      Booking.create!(dtstart: "2019-10-13", dtend: "2019-10-14", house: house, room: room, room_unit: room_units.sample, user: guest)
      Booking.create!(dtstart: "2019-10-16", dtend: "2019-10-20", house: house, room: room, room_unit: room_units.sample, user: guest)

      # Act
      dtstart = Date.iso8601('2019-10-10')
      dtend = Date.iso8601('2019-10-22')
      available_dates = Room.first.availability_between_dates(dtstart, dtend)

      # Assert
      expect(available_dates).to include_json({
                                                  total_rooms: 10,
                                                  start_date: '2019-10-10',
                                                  end_date: '2019-10-22',
                                                  payload: [
                                                      {:allotment=>10, :date=>"2019-10-10"},
                                                      {:allotment=>9, :date=>"2019-10-11"},
                                                      {:allotment=>10, :date=>"2019-10-12"},
                                                      {:allotment=>9, :date=>"2019-10-13"},
                                                      {:allotment=>10, :date=>"2019-10-14"},
                                                      {:allotment=>10, :date=>"2019-10-15"},
                                                      {:allotment=>9, :date=>"2019-10-16"},
                                                      {:allotment=>9, :date=>"2019-10-17"},
                                                      {:allotment=>9, :date=>"2019-10-18"},
                                                      {:allotment=>9, :date=>"2019-10-19"},
                                                      {:allotment=>10, :date=>"2019-10-20"},
                                                      {:allotment=>10, :date=>"2019-10-21"},
                                                      {:allotment=>10, :date=>"2019-10-22"}]
                                              })
    end

    it 'with multiple rooms' do
      # Arrange
      house = House.create!(name: Faker::GameOfThrones.character)
      guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)

      room1 = house.rooms.create!(name: Faker::GameOfThrones.character)
      room2 = house.rooms.create!(name: Faker::GameOfThrones.character)
      room1_units = []
      room2_units = []
      10.times.each do
        room1_units << room1.room_units.create!(room_no: Faker::Number.number(4), house: house)
      end
      10.times.each do
        room2_units << room2.room_units.create!(room_no: Faker::Number.number(4), house: house)
      end
      Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room1, room_unit: room1_units.sample, user: guest)
      Booking.create!(dtstart: "2019-10-13", dtend: "2019-10-14", house: house, room: room1, room_unit: room1_units.sample,  user: guest)
      Booking.create!(dtstart: "2019-10-16", dtend: "2019-10-20", house: house, room: room1, room_unit: room1_units.sample,  user: guest)


      Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room2, room_unit: room2_units.sample,  user: guest)
      Booking.create!(dtstart: "2019-10-12", dtend: "2019-10-13", house: house, room: room2, room_unit: room2_units.sample,  user: guest)
      Booking.create!(dtstart: "2019-10-13", dtend: "2019-10-14", house: house, room: room2, room_unit: room2_units.sample,  user: guest)

      # Act
      dtstart = Date.iso8601('2019-10-10')
      dtend = Date.iso8601('2019-10-22')
      available_dates = Room.first.availability_between_dates(dtstart, dtend)

      # Assert
      expect(available_dates).to include_json({
                                                  total_rooms: 10,
                                                  start_date: '2019-10-10',
                                                  end_date: '2019-10-22',
                                                  payload: [
                                                      {:allotment=>10, :date=>"2019-10-10"},
                                                      {:allotment=>9, :date=>"2019-10-11"},
                                                      {:allotment=>10, :date=>"2019-10-12"},
                                                      {:allotment=>9, :date=>"2019-10-13"},
                                                      {:allotment=>10, :date=>"2019-10-14"},
                                                      {:allotment=>10, :date=>"2019-10-15"},
                                                      {:allotment=>9, :date=>"2019-10-16"},
                                                      {:allotment=>9, :date=>"2019-10-17"},
                                                      {:allotment=>9, :date=>"2019-10-18"},
                                                      {:allotment=>9, :date=>"2019-10-19"},
                                                      {:allotment=>10, :date=>"2019-10-20"},
                                                      {:allotment=>10, :date=>"2019-10-21"},
                                                      {:allotment=>10, :date=>"2019-10-22"}]
                                              })
    end

    it "connected room units across room types" do
      # Arrange
      house = House.create!(name: Faker::GameOfThrones.character)
      guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
      roomAB = house.rooms.create!(name: Faker::GameOfThrones.character)
      roomC = house.rooms.create!(name: Faker::GameOfThrones.character)

      #          C
      #       /     \
      #     A        B

      unitC = roomC.room_units.create!(room_no: Faker::Number.number(4), house: house, virtual: true)
      unitA = roomAB.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
      unitB = roomAB.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)

      Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: roomAB, room_unit: unitA, user: guest) # Book A
      Booking.create!(dtstart: "2019-10-12", dtend: "2019-10-13", house: house, room: roomAB, room_unit: unitB, user: guest) # Book B
      Booking.create!(dtstart: "2019-10-13", dtend: "2019-10-14", house: house, room: roomC, room_unit: unitC, user: guest) # Book C, Block A and B

      Booking.create!(dtstart: "2019-10-14", dtend: "2019-10-17", house: house, room: roomAB, room_unit: unitA, user: guest) # Book A
      Booking.create!(dtstart: "2019-10-14", dtend: "2019-10-15", house: house, room: roomAB, room_unit: unitB, user: guest) # Book B

      # Act
      dtstart = Date.iso8601('2019-10-10')
      dtend = Date.iso8601('2019-10-18')
      roomC_available_dates = roomC.availability_between_dates(dtstart, dtend)
      roomAB_available_dates = roomAB.availability_between_dates(dtstart, dtend)

      # Assert
      expect(roomC_available_dates).to include_json({
                                                        total_rooms: 1,
                                                        start_date: '2019-10-10',
                                                        end_date: '2019-10-18',
                                                        payload: [
                                                            {:allotment=>1, :date=>"2019-10-10"},
                                                            {:allotment=>0, :date=>"2019-10-11"},
                                                            {:allotment=>0, :date=>"2019-10-12"},
                                                            {:allotment=>0, :date=>"2019-10-13"},
                                                            {:allotment=>0, :date=>"2019-10-14"},
                                                            {:allotment=>0, :date=>"2019-10-15"},
                                                            {:allotment=>0, :date=>"2019-10-16"},
                                                            {:allotment=>1, :date=>"2019-10-17"}]
                                                    })

      expect(roomAB_available_dates).to include_json({
                                                         total_rooms: 2,
                                                         start_date: '2019-10-10',
                                                         end_date: '2019-10-18',
                                                         payload: [
                                                             {:allotment=>2, :date=>"2019-10-10"},
                                                             {:allotment=>1, :date=>"2019-10-11"},
                                                             {:allotment=>1, :date=>"2019-10-12"},
                                                             {:allotment=>0, :date=>"2019-10-13"},
                                                             {:allotment=>0, :date=>"2019-10-14"},
                                                             {:allotment=>1, :date=>"2019-10-15"},
                                                             {:allotment=>1, :date=>"2019-10-16"},
                                                             {:allotment=>2, :date=>"2019-10-17"}]
                                                     })
    end

    it "ignore overlap bookings" do
      # Arrange
      house = House.create!(name: Faker::GameOfThrones.character)
      guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
      roomAB = house.rooms.create!(name: Faker::GameOfThrones.character)
      roomC = house.rooms.create!(name: Faker::GameOfThrones.character)

      #          C
      #       /     \
      #     A        B

      unitC = roomC.room_units.create!(room_no: Faker::Number.number(4), house: house, virtual: true)
      unitA = roomAB.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)
      unitB = roomAB.room_units.create!(room_no: Faker::Number.number(4), house: house, part_of_room:  unitC)

      Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: roomAB, room_unit: unitA, user: guest) # Book A
      Booking.create!(dtstart: "2019-10-12", dtend: "2019-10-13", house: house, room: roomAB, room_unit: unitB, user: guest) # Book B
      Booking.create!(dtstart: "2019-10-13", dtend: "2019-10-14", house: house, room: roomC, room_unit: unitC, user: guest) # Book C, Block A and B

      Booking.create!(dtstart: "2019-10-14", dtend: "2019-10-17", house: house, room: roomAB, room_unit: unitA, user: guest) # Book A
      Booking.create!(dtstart: "2019-10-14", dtend: "2019-10-15", house: house, room: roomAB, room_unit: unitB, user: guest) # Book B

      # overlaps
      Booking.create!(dtstart: "2019-10-14", dtend: "2019-10-17", house: house, room: roomAB, room_unit: unitA, user: guest) # Book A
      Booking.create!(dtstart: "2019-10-14", dtend: "2019-10-15", house: house, room: roomAB, room_unit: unitB, user: guest) # Book B

      # Act
      dtstart = Date.iso8601('2019-10-10')
      dtend = Date.iso8601('2019-10-18')
      roomC_available_dates = roomC.availability_between_dates(dtstart, dtend)
      roomAB_available_dates = roomAB.availability_between_dates(dtstart, dtend)

      # Assert
      expect(roomC_available_dates).to include_json({
                                                        total_rooms: 1,
                                                        start_date: '2019-10-10',
                                                        end_date: '2019-10-18',
                                                        payload: [
                                                            {:allotment=>1, :date=>"2019-10-10"},
                                                            {:allotment=>0, :date=>"2019-10-11"},
                                                            {:allotment=>0, :date=>"2019-10-12"},
                                                            {:allotment=>0, :date=>"2019-10-13"},
                                                            {:allotment=>0, :date=>"2019-10-14"},
                                                            {:allotment=>0, :date=>"2019-10-15"},
                                                            {:allotment=>0, :date=>"2019-10-16"},
                                                            {:allotment=>1, :date=>"2019-10-17"}]
                                                    })

      expect(roomAB_available_dates).to include_json({
                                                         total_rooms: 2,
                                                         start_date: '2019-10-10',
                                                         end_date: '2019-10-18',
                                                         payload: [
                                                             {:allotment=>2, :date=>"2019-10-10"},
                                                             {:allotment=>1, :date=>"2019-10-11"},
                                                             {:allotment=>1, :date=>"2019-10-12"},
                                                             {:allotment=>0, :date=>"2019-10-13"},
                                                             {:allotment=>0, :date=>"2019-10-14"},
                                                             {:allotment=>1, :date=>"2019-10-15"},
                                                             {:allotment=>1, :date=>"2019-10-16"},
                                                             {:allotment=>2, :date=>"2019-10-17"}]
                                                     })
    end
  end
end
