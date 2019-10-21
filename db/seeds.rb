# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#

puts 'create houses'

Booking.destroy_all
User.destroy_all
RoomUnit.destroy_all
Room.destroy_all
House.destroy_all

1.times.each do
  house = House.create!(
      # is_master: true,
      # status: :listed,
      name: Faker::GameOfThrones.character,
      # address: Faker::Address.full_address,
      )
  #each hotel will have 3 room types
  3.times.each do
    room = house.rooms.create!( #is_master: true,
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
