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

ActiveRecord::Schema.define(version: 20160530221659) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"
  enable_extension "pgcrypto"
  enable_extension "cube"
  enable_extension "earthdistance"

  create_table "conversation_healths", id: :bigserial, force: :cascade do |t|
    t.jsonb    "properties",                default: {}
    t.integer  "conversation_id", limit: 8,              null: false
    t.uuid     "profile_uuid",                           null: false
    t.datetime "recorded_at",                            null: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  add_index "conversation_healths", ["conversation_id"], name: "index_conversation_healths_on_conversation_id", using: :btree
  add_index "conversation_healths", ["profile_uuid"], name: "index_conversation_healths_on_profile_uuid", using: :btree

  create_table "conversations", id: :bigserial, force: :cascade do |t|
    t.uuid     "uuid",             default: "gen_random_uuid()"
    t.jsonb    "properties",       default: {},                  null: false
    t.string   "state",                                          null: false
    t.jsonb    "state_properties", default: {},                  null: false
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
  end

  add_index "conversations", ["properties"], name: "idx_gin_conversations", using: :gin
  add_index "conversations", ["uuid"], name: "index_conversations_on_uuid", using: :btree

  create_table "date_places", force: :cascade do |t|
    t.jsonb    "properties", default: {}
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "date_suggestions", force: :cascade do |t|
    t.jsonb    "properties",                default: {}
    t.integer  "conversation_id", limit: 8,              null: false
    t.integer  "date_place_id",                          null: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  add_index "date_suggestions", ["conversation_id"], name: "index_date_suggestions_on_conversation_id", using: :btree
  add_index "date_suggestions", ["date_place_id"], name: "index_date_suggestions_on_date_place_id", using: :btree

  create_table "event_rsvps", force: :cascade do |t|
    t.jsonb    "properties",   default: {}, null: false
    t.uuid     "profile_uuid",              null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "event_rsvps", ["profile_uuid"], name: "index_event_rsvps_on_profile_uuid", using: :btree

  create_table "matches", id: :bigserial, force: :cascade do |t|
    t.uuid     "for_profile_uuid",                  null: false
    t.uuid     "matched_profile_uuid",              null: false
    t.jsonb    "properties",           default: {}, null: false
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  add_index "matches", ["for_profile_uuid"], name: "index_matches_on_for_profile_uuid", using: :btree
  add_index "matches", ["matched_profile_uuid"], name: "index_matches_on_matched_profile_uuid", using: :btree

  create_table "messages", id: :bigserial, force: :cascade do |t|
    t.integer  "conversation_id", limit: 8,              null: false
    t.uuid     "sender_uuid",                            null: false
    t.uuid     "recipient_uuid",                         null: false
    t.jsonb    "properties",                default: {}, null: false
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  add_index "messages", ["conversation_id"], name: "index_messages_on_conversation_id", using: :btree
  add_index "messages", ["recipient_uuid"], name: "index_messages_on_recipient_uuid", using: :btree
  add_index "messages", ["sender_uuid"], name: "index_messages_on_sender_uuid", using: :btree

  create_table "photos", force: :cascade do |t|
    t.jsonb    "properties",   default: {}, null: false
    t.uuid     "profile_uuid",              null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "photos", ["profile_uuid"], name: "index_photos_on_profile_uuid", using: :btree

  create_table "profile_event_logs", force: :cascade do |t|
    t.uuid     "profile_uuid",              null: false
    t.string   "event_name",                null: false
    t.jsonb    "properties",   default: {}, null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "profile_event_logs", ["event_name"], name: "index_profile_event_logs_on_event_name", using: :btree
  add_index "profile_event_logs", ["profile_uuid"], name: "index_profile_event_logs_on_profile_uuid", using: :btree

  create_table "profiles", primary_key: "uuid", force: :cascade do |t|
    t.jsonb    "properties",                               default: {}, null: false
    t.string   "state",                                                 null: false
    t.jsonb    "state_properties",                         default: {}, null: false
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.decimal  "search_lat",       precision: 7, scale: 4
    t.decimal  "search_lng",       precision: 7, scale: 4
  end

  add_index "profiles", ["created_at"], name: "index_profiles_on_created_at", using: :btree
  add_index "profiles", ["properties"], name: "idx_gin_profiles", using: :gin
  add_index "profiles", ["updated_at"], name: "index_profiles_on_updated_at", using: :btree

  create_table "real_dates", id: :bigserial, force: :cascade do |t|
    t.jsonb    "properties",                default: {}
    t.integer  "conversation_id", limit: 8,              null: false
    t.uuid     "profile_uuid",                           null: false
    t.integer  "date_place_id"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  add_index "real_dates", ["conversation_id"], name: "index_real_dates_on_conversation_id", using: :btree
  add_index "real_dates", ["date_place_id"], name: "index_real_dates_on_date_place_id", using: :btree
  add_index "real_dates", ["profile_uuid"], name: "index_real_dates_on_profile_uuid", using: :btree

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

  add_foreign_key "conversation_healths", "conversations"
  add_foreign_key "conversation_healths", "profiles", column: "profile_uuid", primary_key: "uuid"
  add_foreign_key "date_suggestions", "conversations"
  add_foreign_key "date_suggestions", "date_places"
  add_foreign_key "event_rsvps", "profiles", column: "profile_uuid", primary_key: "uuid"
  add_foreign_key "matches", "profiles", column: "for_profile_uuid", primary_key: "uuid"
  add_foreign_key "matches", "profiles", column: "matched_profile_uuid", primary_key: "uuid"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "profiles", column: "recipient_uuid", primary_key: "uuid"
  add_foreign_key "messages", "profiles", column: "sender_uuid", primary_key: "uuid"
  add_foreign_key "photos", "profiles", column: "profile_uuid", primary_key: "uuid"
  add_foreign_key "profile_event_logs", "profiles", column: "profile_uuid", primary_key: "uuid"
  add_foreign_key "real_dates", "conversations"
  add_foreign_key "real_dates", "date_places"
  add_foreign_key "real_dates", "profiles", column: "profile_uuid", primary_key: "uuid"
  add_foreign_key "social_authentications", "profiles", column: "profile_uuid", primary_key: "uuid"
end
