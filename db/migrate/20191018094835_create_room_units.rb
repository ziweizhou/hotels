class CreateRoomUnits < ActiveRecord::Migration[5.2]
  def change
    create_table :room_units do |t|
      t.integer :room_no
      t.references :house, foreign_key: true

      t.timestamps
    end
  end
end
