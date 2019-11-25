# frozen_string_literal: true

require 'rails_helper'
require 'date'

RSpec.describe Booking, type: :model do
  before(:each) do
    DatabaseCleaner.clean
  end

  context '#create' do

    # +---+----------------+--------------+
    # | 1 | Lorent Lorch 1 | Ocean View 1 | 
    # +---+                +--------------+
    # | 2 |                | Ocean View 2 |
    # +---+----------------+--------------+
    # | 3 | Lorent Lorch 2 | Ocean View 3 |
    # +---+                +--------------+
    # | 4 |                | River 1      |
    # +---+----------------+              +
    # | 5 |                |              |
    # +---+                +--------------+
    # | 6 |     Pond 1     | River 2      |
    # +---+                +              +
    # | 7 |                |              |
    # +---+----------------+--------------+

    rooms = [
        { type: 'Pond', name: 'Pond 1', units: [5, 6, 7] },
        { type: 'Lorent Lorch', name: 'Lorent Lorch 1', units: [1, 2] },
        { type: 'Lorent Lorch', name: 'Lorent Lorch 2', units: [3, 4] },
        { type: 'River', name: 'River 1', units: [4, 5] },
        { type: 'River', name: 'River 2', units: [6, 7] },
        { type: 'Ocean View', name: 'Ocean View 1', units: [1] },
        { type: 'Ocean View', name: 'Ocean View 2', units: [2] },
        { type: 'Ocean View', name: 'Ocean View 3', units: [3] }
    ]
    test_cases = [
        {
            title: 'Creates bookings when available 1',
            rooms: rooms,
            bookings: [
                { dtstart: '2019-10-01', dtend: '2019-10-02', room_type: 'Ocean View' },
                { dtstart: '2019-10-01', dtend: '2019-10-02', room_type: 'River' },
                { dtstart: '2019-10-01', dtend: '2019-10-02', room_type: 'Lorent Lorch' }
            ],
            expect: {
                dtstart: '2019-10-01',
                dtend: '2019-10-02',
                booking_count: 3,
                available_count: 1,
                booking_types: ['Ocean View', 'River', 'Lorent Lorch']
            }
        },

        {
            title: 'Creates bookings when available 2',
            rooms: rooms,
            bookings: [
                { dtstart: '2019-10-01', dtend: '2019-10-02', room_type: 'Ocean View' },
                { dtstart: '2019-10-01', dtend: '2019-10-02', room_type: 'Ocean View' },
                { dtstart: '2019-10-01', dtend: '2019-10-02', room_type: 'Ocean View' },
                { dtstart: '2019-10-01', dtend: '2019-10-02', room_type: 'Pond' }
            ],
            expect: {
                dtstart: '2019-10-01',
                dtend: '2019-10-02',
                booking_count: 4,
                available_count: 0,
                booking_types: ['Ocean View', 'Ocean View', 'Ocean View', 'Pond']
            }
        },

        {
            title: 'Creates bookings when available 3',
            rooms: rooms,
            bookings: [
                { dtstart: '2019-10-01', dtend: '2019-10-02', room_type: 'Lorent Lorch' },
                { dtstart: '2019-10-01', dtend: '2019-10-02', room_type: 'Ocean View' },
                { dtstart: '2019-10-01', dtend: '2019-10-02', room_type: 'Ocean View' },
                { dtstart: '2019-10-01', dtend: '2019-10-02', room_type: 'Pond' }
            ],
            expect: {
                dtstart: '2019-10-01',
                dtend: '2019-10-02',
                booking_count: 4,
                available_count: 0,
                booking_types: ['Ocean View', 'Ocean View', 'Lorent Lorch', 'Pond']
            }
        },

        {
            title: 'Creates bookings when available 4',
            rooms: rooms,
            bookings: [
                { dtstart: '2019-10-01', dtend: '2019-10-05', room_type: 'Pond' },
                { dtstart: '2019-10-05', dtend: '2019-10-10', room_type: 'Pond' },
                { dtstart: '2019-10-10', dtend: '2019-10-15', room_type: 'River' },
                { dtstart: '2019-10-10', dtend: '2019-10-15', room_type: 'River' }
            ],
            expect: {
                dtstart: '2019-10-01',
                dtend: '2019-10-15',
                booking_count: 4,
                available_count: 4,
                booking_types: %w[Pond Pond River River]
            }
        },

        {
            title: 'Raises error during conflict 1',
            rooms: rooms,
            bookings: [
                { dtstart: '2019-10-01', dtend: '2019-10-05', room_type: 'Pond' },
                { dtstart: '2019-10-04', dtend: '2019-10-10', room_type: 'Pond' }
            ],
            expect: {
                dtstart: '2019-10-01',
                dtend: '2019-10-10',
                booking_count: 1,
                available_count: nil,
                booking_types: ['Pond'],
                error: true
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
          begin
            Booking.create!(dtstart: booking[:dtstart], dtend: booking[:dtend], house: house, room_type: room_types[booking[:room_type]], user: guest)
          rescue StandardError => err
            raise err unless test_case[:expect][:error]
          end
        end

        # Assert
        booking = Booking.new
        allocations = booking.check_availability(Date.parse(test_case[:expect][:dtstart]), Date.parse(test_case[:expect][:dtend]))
        available_rooms = booking.room_status(Date.parse(test_case[:expect][:dtstart]), Date.parse(test_case[:expect][:dtend])).map{|r| r[:name]}
        bookings = Booking.all
        expect(allocations.count).to eql(test_case[:expect][:booking_count])
        expect(bookings.count).to eql(test_case[:expect][:booking_count])
        expect(available_rooms.count).to eql(test_case[:expect][:available_count]) unless test_case[:expect][:available_count].nil?
        expect(allocations.map { |r| r[:room][:room_type] }).to contain_exactly(*test_case[:expect][:booking_types])
      end
    end
  end

  xcontext '#update' do
    it 'mark as cancel' do

    end

    it 'reschedule dates' do

    end

    it 'throws error when reschedule dates are not available' do

    end
  end

  xcontext '#destroy' do
    it 'should destroy booking' do

    end
  end
end
