class CreateRooms < ActiveRecord::Migration[5.2]
  def change
    create_table :rooms do |t|
      t.string :name
      t.integer :part_of_room_id
      t.references :house, foreign_key: true

      t.timestamps
    end
  end
end
