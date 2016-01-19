# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160119001947) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"
  enable_extension "pgcrypto"

  create_table "photos", force: :cascade do |t|
    t.jsonb    "properties",   default: {}, null: false
    t.uuid     "profile_uuid",              null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "photos", ["profile_uuid"], name: "index_photos_on_profile_uuid", using: :btree

  create_table "profiles", primary_key: "uuid", force: :cascade do |t|
    t.jsonb    "properties", default: {}, null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "profiles", ["created_at"], name: "index_profiles_on_created_at", using: :btree
  add_index "profiles", ["updated_at"], name: "index_profiles_on_updated_at", using: :btree

  create_table "social_authentications", force: :cascade do |t|
    t.string   "oauth_uid"
    t.string   "oauth_provider"
    t.string   "oauth_token"
    t.string   "oauth_token_expiration"
    t.jsonb    "oauth_hash"
    t.uuid     "profile_uuid",           null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "social_authentications", ["oauth_provider", "oauth_uid"], name: "index_social_authentications_on_oauth_provider_and_oauth_uid", unique: true, using: :btree
  add_index "social_authentications", ["profile_uuid"], name: "index_social_authentications_on_profile_uuid", using: :btree

  add_foreign_key "photos", "profiles", column: "profile_uuid", primary_key: "uuid"
  add_foreign_key "social_authentications", "profiles", column: "profile_uuid", primary_key: "uuid"
end
