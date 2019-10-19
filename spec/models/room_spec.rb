# frozen_string_literal: true

require 'rails_helper'
require 'date'

RSpec.describe Room, type: :model do
  before(:each) do
   DatabaseCleaner.clean
  end
  context '#availability_between_dates' do
    it 'returns available dates' do
      # Arrange
      house = House.create!(name: Faker::GameOfThrones.character)
      guest = User.create(name: Faker::Name.name,email: Faker::Internet.email,phone: Faker::PhoneNumber.cell_phone)
      room = house.rooms.create!(name: Faker::GameOfThrones.character)
      10.times.each do
        room.room_units.create!(room_no: Faker::Number.number(4), house: house)
      end
      Booking.create!(dtstart: "2019-10-11", dtend: "2019-10-12", house: house, room: room, user: guest)
      Booking.create!(dtstart: "2019-10-13", dtend: "2019-10-14", house: house, room: room, user: guest)
      Booking.create!(dtstart: "2019-10-16", dtend: "2019-10-20", house: house, room: room, user: guest)
      
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
  end
end
