class CreateBookings < ActiveRecord::Migration[5.2]
  def change
    create_table :bookings do |t|
      t.string :summary
      t.text :description
      t.string :status
      t.date :dtstart
      t.date :dtend
      t.references :house, foreign_key: true
      t.references :room, foreign_key: true
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
