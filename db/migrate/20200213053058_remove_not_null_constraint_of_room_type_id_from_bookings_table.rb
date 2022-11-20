class RemoveNotNullConstraintOfRoomTypeIdFromBookingsTable < ActiveRecord::Migration[5.2]
  def change
    change_column_null :bookings, :room_type_id, true
  end
end
