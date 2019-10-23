# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_10_18_095330) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bookings", force: :cascade do |t|
    t.string "summary"
    t.text "description"
    t.string "status"
    t.date "dtstart"
    t.date "dtend"
    t.integer "parent_booking_id"
    t.bigint "house_id"
    t.bigint "room_id"
    t.bigint "room_unit_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["house_id"], name: "index_bookings_on_house_id"
    t.index ["room_id"], name: "index_bookings_on_room_id"
    t.index ["room_unit_id"], name: "index_bookings_on_room_unit_id"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "houses", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "room_units", force: :cascade do |t|
    t.integer "room_no"
    t.integer "part_of_room_id"
    t.boolean "virtual", default: false
    t.bigint "house_id"
    t.bigint "room_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["house_id"], name: "index_room_units_on_house_id"
    t.index ["room_id"], name: "index_room_units_on_room_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "name"
    t.bigint "house_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["house_id"], name: "index_rooms_on_house_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "bookings", "houses"
  add_foreign_key "bookings", "room_units"
  add_foreign_key "bookings", "rooms"
  add_foreign_key "bookings", "users"
  add_foreign_key "room_units", "houses"
  add_foreign_key "room_units", "rooms"
  add_foreign_key "rooms", "houses"
end
