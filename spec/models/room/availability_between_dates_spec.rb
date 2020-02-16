require 'rails_helper'
require 'date'

RSpec.describe Room, type: :model do
  context "#availability_between_dates" do
    let(:num_of_houses) { 1 }
    let(:num_of_rooms) { 3 }
    let(:num_of_room_units) { 3 }
    let(:num_of_bookings) { 0 }
    let(:houses) {
      num_of_houses.times.map do
        House.create!(is_master: true,
          status: :listed,
          name: Faker::GameOfThrones.character,
          address: Faker::Address.full_address,
        )
      end
    }
    let(:rooms) {
      houses.reduce([]) do |rooms, house|
        rooms.concat(num_of_rooms.times.map do
          house.rooms.create!(is_master: true,
            name: Faker::GameOfThrones.character
          )
        end)
      end
    }
    let(:room_units) {
      rooms.reduce([]) do |room_units, room|
        room_units.concat(num_of_room_units.times.map do
          room.room_units.create!(room_no: Faker::Number.number(4), house: room.house)
        end)
      end
    }
    let(:bookings) {
      rooms.reduce([]) do |bookings, room|
        num_of_bookings.times.each do
          future_dtstart = Date.current.tomorrow + rand(10)
          future_dtend = future_dtstart + (1 + rand(10))
          past_dtend = Date.current.yesterday - rand(10)
          past_dtstart = past_dtend - (1 + rand(10))

          bookings.concat([[future_dtstart, future_dtend], [past_dtstart, past_dtend]].map do |dtstart, dtend|
            create_booking(room, dtstart, dtend)
          end)
        end

        bookings
      end
    }
    let(:start_date) { "2019-10-11" }
    let(:end_date) { "2019-10-20" }
    let(:dates_enumeration) { get_dates_enumeration(start_date, end_date) }
    let(:house) { houses.first }
    let(:room) { house.rooms.first }
    let(:result) { room.availability_between_dates(start_date, end_date) }

    before(:each) do
      room_units
      bookings
    end

    context "setup" do
      let(:num_of_bookings) { 10 }

      it "should have correct number of houses" do
        expect(House.all.length).to eq(num_of_houses)
      end

      it "should have correct number of rooms" do
        expect(Room.all.length).to eq(num_of_houses * num_of_rooms)
      end

      it "should have correct number of room units" do
        expect(RoomUnit.all.length).to eq(num_of_houses * num_of_rooms * num_of_room_units)
      end

      it "should have correct number of bookings" do
        expect(Booking.all.length).to eq(num_of_houses * num_of_rooms * num_of_bookings * 2)
      end
    end

    context "attributes other than payload" do
      it "should return correct total_rooms" do
        expect(result[:total_rooms]).to eq(num_of_room_units)
      end

      it "should return correct start_date" do
        expect(result[:start_date]).to eq(start_date)
      end

      it "should return correct end_date" do
        expect(result[:end_date]).to eq(end_date)
      end
    end

    context "payload attribute" do
      let(:expected_payload_param_list) { [] }

      it "should return payload with correct length" do
        correct_length = dates_enumeration.count
        expect(result[:payload].length).to eq(correct_length)
      end

      shared_context "assert payload" do
        it "should return payload with correct allotment" do
          assert_payload(*expected_payload_param_list)
        end
      end

      context "without room units assignment" do
        context "with no bookings" do
          let(:bookings) { [] }

          include_context "assert payload"
        end

        context "with an unrelated booking" do
          let(:bookings) {
            [
              create_booking(room, "2019-10-21", "2019-10-22")
            ]
          }

          include_context "assert payload"
        end

        context "with a single booking 1" do
          let(:bookings) {
            [
              create_booking(room, "2019-10-11", "2019-10-14")
            ]
          }
          let(:expected_payload_param_list) {
            [["2019-10-11", "2019-10-13", 1]]
          }

          include_context "assert payload"
        end

        context "with a single booking 2" do
          let(:bookings) {
            [
              create_booking(room, "2019-10-10", "2019-10-22")
            ]
          }
          let(:expected_payload_param_list) {
            [["2019-10-11", "2019-10-20", 1]]
          }

          include_context "assert payload"
        end

        context "with a single booking 3" do
          let(:bookings) {
            [
              create_booking(room, "2019-10-10", "2019-10-20")
            ]
          }
          let(:expected_payload_param_list) {
            [["2019-10-11", "2019-10-19", 1]]
          }

          include_context "assert payload"
        end

        context "with a single booking 4" do
          let(:bookings) {
            [
              create_booking(room, "2019-10-14", "2019-10-25")
            ]
          }
          let(:expected_payload_param_list) {
            [["2019-10-14", "2019-10-20", 1]]
          }

          include_context "assert payload"
        end

        context "with multiple bookings 1" do
          let(:bookings) {
            [
              create_booking(room, "2019-10-14", "2019-10-25"),
              create_booking(room, "2019-10-08", "2019-10-12")
            ]
          }
          let(:expected_payload_param_list) {
            [
              ["2019-10-14", "2019-10-20", 1],
              ["2019-10-10", "2019-10-11", 1]
            ]
          }

          include_context "assert payload"
        end

        context "with multiple bookings 2" do
          let(:bookings) {
            [
              create_booking(room, "2019-10-14", "2019-10-25"),
              create_booking(room, "2019-10-08", "2019-10-16")
            ]
          }
          let(:expected_payload_param_list) {
            [
              ["2019-10-10", "2019-10-13", 1],
              ["2019-10-14", "2019-10-15", 2],
              ["2019-10-16", "2019-10-20", 1]
            ]
          }

          include_context "assert payload"
        end

        context "with multiple bookings 3" do
          let(:bookings) {
            [
              create_booking(room, "2019-10-08", "2019-10-25"),
              create_booking(room, "2019-10-12", "2019-10-14")
            ]
          }
          let(:expected_payload_param_list) {
            [
              ["2019-10-10", "2019-10-11", 1],
              ["2019-10-12", "2019-10-13", 2],
              ["2019-10-14", "2019-10-20", 1]
            ]
          }

          include_context "assert payload"
        end

        context "with oversold bookings" do
          let(:bookings) {
            [
              create_booking(room, "2019-10-11", "2019-10-14"),
              create_booking(room, "2019-10-12", "2019-10-14"),
              create_booking(room, "2019-10-13", "2019-10-14"),
              create_booking(room, "2019-10-13", "2019-10-18"),
            ]
          }
          let(:expected_payload_param_list) {
            [
              ["2019-10-11", "2019-10-11", 1],
              ["2019-10-12", "2019-10-12", 2],
              ["2019-10-13", "2019-10-13", 4],
              ["2019-10-14", "2019-10-17", 1]
            ]
          }

          include_context "assert payload"
        end
      end

      context "with room units assignment" do
        let(:bookings) {
          [
            create_booking(room, "2019-10-11", "2019-10-14"),
            create_booking(room, "2019-10-15", "2019-10-20", room_units.first)
          ]
        }
        let(:expected_payload_param_list) {
          [
            ["2019-10-11", "2019-10-13", 1],
            ["2019-10-15", "2019-10-19", 1]
          ]
        }

        include_context "assert payload"
      end

      context "with connected room" do
        context "sample cases" do
          let(:start_date) { "2019-10-11" }
          let(:end_date) { "2019-10-12" }
          let(:num_of_room_units) { 1 }
          let(:family_room) {
            house.rooms.create!(
              is_master: true,
              name: "Family Room Style"
            )
          }
          let(:connected_unit) {
            num_of_room_units.times.map do
              family_room.room_units.create!(room_no: Faker::Number.number(4), house: family_room.house)
            end.first
          }
          let(:unit1) {
            unit = RoomUnit.first
            unit.part_of_room = connected_unit
            unit.save
            unit
          }
          let(:unit2) {
            unit = RoomUnit.second
            unit.part_of_room = connected_unit
            unit.save
            unit
          }

          before(:each) do
            family_room
            connected_unit
            unit1
            unit2
          end

          context "setup" do
            it "should have correct number of room units for the connected unit" do
              expect(connected_unit.room.room_units.size).to eq(num_of_room_units)
            end
          end

          context "family room's availability after a sub room unit is booked" do
            let(:bookings) {
              [
                create_booking(room, "2019-10-11", "2019-10-12", unit1)
              ]
            }
            let(:room) { family_room }
            let(:expected_payload_param_list) {
              [
                ["2019-10-11", "2019-10-11", 1]
              ]
            }

            include_context "assert payload"
          end

          context "sub room units' room availability after the connected unit is booked" do
            let(:bookings) {
              [
                create_booking(room, "2019-10-11", "2019-10-12", connected_unit)
              ]
            }

            context "unit1" do
              let(:room) { unit1.room }
              let(:expected_payload_param_list) {
                [
                  ["2019-10-11", "2019-10-11", 1]
                ]
              }

              include_context "assert payload"
            end

            context "unit2" do
              let(:room) { unit2.room }
              let(:expected_payload_param_list) {
                [
                  ["2019-10-11", "2019-10-11", 1]
                ]
              }

              include_context "assert payload"
            end
          end
        end

        context "more complex cases" do
          let(:start_date) { "2019-10-11" }
          let(:end_date) { "2019-10-15" }

          # family room -> 2 units
          #   -> room 1 consists of deluxe 101 and 102
          #   -> room 2 consists of deluxe 103 and 104
          # deluxe -> 4 units
          # 1 booking with 3 days of family room 1
          # availability for both of them
          let(:family_room) {
            house.rooms.create!(
              is_master: true,
              name: "Family Room Style"
            )
          }
          let(:deluxe_room) {
            house.rooms.create!(
              is_master: true,
              name: "Deluxe Room Style"
            )
          }
          let(:num_of_family_units) { 2 }
          let(:family_units) {
            num_of_family_units.times.map do
              family_room.room_units.create!(room_no: Faker::Number.number(4), house: family_room.house)
            end
          }
          let(:num_of_deluxe_units) { 4 }
          let(:deluxe_units) {
            num_of_deluxe_units.times.map do |i|
              unit = deluxe_room.room_units.create!(room_no: Faker::Number.number(4), house: deluxe_room.house)
              unit.part_of_room = family_units[i % num_of_family_units]
              unit.save
              unit
            end
          }

          before(:each) do
            family_room
            family_units
            deluxe_room
            deluxe_units
          end

          shared_context "with one family room booking" do
            let(:bookings) {
              [
                create_booking(family_room, "2019-10-11", "2019-10-14", family_units.first)
              ]
            }
          end

          shared_context "with two family room bookings" do
            let(:bookings) {
              [
                create_booking(family_room, "2019-10-11", "2019-10-14", family_units.first),
                create_booking(family_room, "2019-10-11", "2019-10-14")
              ]
            }
          end

          shared_context "with two deluxe room bookings" do
            let(:bookings) {
              [
                create_booking(deluxe_room, "2019-10-11", "2019-10-14", deluxe_units.second),
                create_booking(deluxe_room, "2019-10-11", "2019-10-14")
              ]
            }
          end

          shared_context "with one more deluxe unit" do
            let(:num_of_deluxe_units) { 5 }
            let(:deluxe_units) {
              deluxe_room.room_units.create!(room_no: Faker::Number.number(4), house: deluxe_room.house)

              (num_of_deluxe_units - 1).times.map do |i|
                unit = deluxe_room.room_units.create!(room_no: Faker::Number.number(4), house: deluxe_room.house)
                unit.part_of_room = family_units[i % num_of_family_units]
                unit.save
                unit
              end
            }
          end

          context "for the family room" do
            let(:room) { family_room }
            let(:num_of_room_units) { num_of_family_units }

            context "with one family room booking" do
              include_context "with one family room booking"

              let(:expected_payload_param_list) {
                [
                  ["2019-10-11", "2019-10-13", 1]
                ]
              }

              include_context "assert payload"
            end

            context "with two family room bookings" do
              include_context "with two family room bookings"

              let(:expected_payload_param_list) {
                [
                  ["2019-10-11", "2019-10-13", 2]
                ]
              }

              include_context "assert payload"

              context "with one more deluxe unit" do
                include_context "with one more deluxe unit"

                let(:expected_payload_param_list) {
                  [
                    ["2019-10-11", "2019-10-13", 2]
                  ]
                }

                include_context "assert payload"
              end
            end

            context "with two deluxe room bookings" do
              include_context "with two deluxe room bookings"

              let(:expected_payload_param_list) {
                [
                  ["2019-10-11", "2019-10-13", 1]
                ]
              }

              include_context "assert payload"
            end
          end

          context "for deluxe room" do
            let(:room) { deluxe_room }
            let(:num_of_room_units) { num_of_deluxe_units }

            context "with one family room booking" do
              include_context "with one family room booking"

              let(:expected_payload_param_list) {
                [
                  ["2019-10-11", "2019-10-13", 2]
                ]
              }

              include_context "assert payload"
            end

            context "with two family room bookings" do
              include_context "with two family room bookings"

              let(:expected_payload_param_list) {
                [
                  ["2019-10-11", "2019-10-13", 4]
                ]
              }

              include_context "assert payload"

              context "with one more deluxe unit" do
                include_context "with one more deluxe unit"

                let(:expected_payload_param_list) {
                  [
                    ["2019-10-11", "2019-10-13", 4]
                  ]
                }

                include_context "assert payload"
              end
            end

            context "with two deluxe room bookings" do
              include_context "with two deluxe room bookings"

              let(:expected_payload_param_list) {
                [
                  ["2019-10-11", "2019-10-13", 2]
                ]
              }

              include_context "assert payload"
            end
          end
        end
      end
    end
  end

  def assert_payload(*params_list)
    expected_dates = get_expected_dates(params_list)

    dates_enumeration.each_with_index do |date, i|
      expect(result[:payload][i][:date]).to eq(date)
      expect(result[:payload][i][:allotment]).to eq(
        expected_dates.has_key?(date) ?
          [num_of_room_units - expected_dates[date], 0].max :
          num_of_room_units
      )
    end
  end

  def get_dates_enumeration(start_date, end_date)
    Date.parse(start_date).upto(Date.parse(end_date)).map { |date| date.strftime("%Y-%m-%d") }
  end

  def get_expected_dates(params_list)
    params_list.reduce({}) do |acc, params|
      start_date, end_date, rooms_occupied = params

      get_dates_enumeration(start_date, end_date).each do |date|
        acc[date] = rooms_occupied
      end

      acc
    end
  end

  def create_booking(room, dtstart, dtend, room_unit = nil)
    guest = User.create(
      name: Faker::Name.name,
      email: Faker::Internet.email,
      phone: Faker::PhoneNumber.cell_phone
    )
    Booking.create(
      house: room.house,
      room: room_unit.nil? ? room : room_unit.room,
      room_unit: room_unit,
      summary: Faker::GameOfThrones.character,
      description: Faker::Lorem.paragraph,
      status: :confirmed,
      user: guest,
      dtstart: dtstart,
      dtend: dtend
    )
  end
end