class CreateRoomUnits < ActiveRecord::Migration[5.2]
  def change
    create_table :room_units do |t|
      t.belongs_to  :room, foreign_key: true
      t.belongs_to  :unit, foreign_key: true
      t.references :house, foreign_key: true

      t.timestamps
    end

    add_index :room_units, [:room_id, :unit_id], :unique => true
  end
end
