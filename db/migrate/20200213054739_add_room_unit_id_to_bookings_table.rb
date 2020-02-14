class AddRoomUnitIdToBookingsTable < ActiveRecord::Migration[5.2]
  def change
    add_column :bookings, :room_unit_id, :bigint
  end
end
