class CreateBookings < ActiveRecord::Migration[5.2]
  def change
    create_table :bookings do |t|
      t.string :summary
      t.text :description
      t.string :status
      t.date :dtstart
      t.date :dtend
      t.integer :parent_booking_id
      t.references :house, foreign_key: true, null: false
      t.references :room_type, foreign_key: true, null: false
      t.references :room, foreign_key: true, null: true
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
