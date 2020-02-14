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

ActiveRecord::Schema.define(version: 2020_02_13_054739) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bookings", force: :cascade do |t|
    t.string "summary"
    t.text "description"
    t.string "status"
    t.date "dtstart"
    t.date "dtend"
    t.integer "parent_booking_id"
    t.bigint "house_id", null: false
    t.bigint "room_type_id"
    t.bigint "room_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "room_unit_id"
    t.index ["house_id"], name: "index_bookings_on_house_id"
    t.index ["room_id"], name: "index_bookings_on_room_id"
    t.index ["room_type_id"], name: "index_bookings_on_room_type_id"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "houses", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_master"
    t.string "status"
    t.string "address"
  end

  create_table "room_types", force: :cascade do |t|
    t.string "name"
    t.bigint "house_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["house_id"], name: "index_room_types_on_house_id"
  end

  create_table "room_units", force: :cascade do |t|
    t.bigint "room_id"
    t.bigint "unit_id"
    t.bigint "house_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "room_no"
    t.index ["house_id"], name: "index_room_units_on_house_id"
    t.index ["room_id", "unit_id"], name: "index_room_units_on_room_id_and_unit_id", unique: true
    t.index ["room_id"], name: "index_room_units_on_room_id"
    t.index ["unit_id"], name: "index_room_units_on_unit_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "name"
    t.bigint "room_type_id"
    t.bigint "house_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_master"
    t.index ["house_id"], name: "index_rooms_on_house_id"
    t.index ["room_type_id"], name: "index_rooms_on_room_type_id"
  end

  create_table "units", force: :cascade do |t|
    t.integer "room_no"
    t.bigint "house_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["house_id"], name: "index_units_on_house_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "bookings", "houses"
  add_foreign_key "bookings", "room_types"
  add_foreign_key "bookings", "rooms"
  add_foreign_key "bookings", "users"
  add_foreign_key "room_types", "houses"
  add_foreign_key "room_units", "houses"
  add_foreign_key "room_units", "rooms"
  add_foreign_key "room_units", "units"
  add_foreign_key "rooms", "houses"
  add_foreign_key "rooms", "room_types"
  add_foreign_key "units", "houses"
end
