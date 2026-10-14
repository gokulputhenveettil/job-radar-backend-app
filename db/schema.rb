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

ActiveRecord::Schema[8.1].define(version: 2026_10_14_061412) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "tracked_jobs", force: :cascade do |t|
    t.string "linkedin_job_id", null: false
    t.string "title", null: false
    t.string "company"
    t.string "location"
    t.string "url", null: false
    t.datetime "posted_at"
    t.boolean "notified", default: false, null: false
    t.boolean "saved", default: false, null: false
    t.boolean "applied", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "dismissed"
    t.index ["linkedin_job_id"], name: "index_tracked_jobs_on_linkedin_job_id", unique: true
    t.index ["saved", "applied", "created_at"], name: "index_tracked_jobs_on_saved_and_applied_and_created_at"
  end
end
