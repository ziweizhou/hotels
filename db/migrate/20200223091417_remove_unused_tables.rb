class RemoveUnusedTables < ActiveRecord::Migration[5.2]
  def change
    remove_column :room_units, :unit_id
    remove_column :bookings, :room_type_id
    remove_column :rooms, :room_type_id
    drop_table :units
    drop_table :room_types
  end
end
