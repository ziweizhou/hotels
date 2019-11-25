class CreateUnits < ActiveRecord::Migration[5.2]
  def change
    create_table :units do |t|
      t.integer :room_no
      t.references :house, foreign_key: true

      t.timestamps
    end
  end
end
