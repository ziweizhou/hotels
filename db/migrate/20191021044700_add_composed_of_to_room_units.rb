class AddComposedOfToRoomUnits < ActiveRecord::Migration[5.2]
  def change
    add_column :room_units, :part_of_room_id, :integer
  end
end
