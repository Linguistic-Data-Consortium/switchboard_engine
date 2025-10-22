# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_10_21_160310) do
  create_table "segments", force: :cascade do |t|
    t.string "filename"
    t.string "channel"
    t.float "beg"
    t.float "end"
    t.integer "turn"
    t.text "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "speakers", force: :cascade do |t|
    t.string "filename"
    t.string "channel"
    t.string "sex"
    t.integer "birth_year"
    t.string "dialect_area"
    t.integer "education"
    t.string "topic_description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "switchboard_engine_segments", force: :cascade do |t|
    t.string "filename"
    t.string "channel"
    t.float "beg"
    t.float "end"
    t.integer "turn"
    t.text "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "switchboard_engine_speakers", force: :cascade do |t|
    t.string "filename"
    t.string "channel"
    t.string "sex"
    t.integer "birth_year"
    t.string "dialect_area"
    t.integer "education"
    t.string "topic_description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
