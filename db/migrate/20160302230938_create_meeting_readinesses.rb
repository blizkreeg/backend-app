class CreateMeetingReadinesses < ActiveRecord::Migration
  def change
    create_table :meeting_readinesses, id: false do |t|
      t.primary_key :id, :bigserial, null: false
      t.jsonb :properties, default: {}
      t.bigint :conversation_id, null: false
      t.uuid :profile_uuid, null: false
      t.datetime :recorded_at, null: false
      t.timestamps null: false
    end

    add_index :meeting_readinesses, :conversation_id
    add_index :meeting_readinesses, :profile_uuid

    add_foreign_key :meeting_readinesses, :conversations
    add_foreign_key :meeting_readinesses, :profiles, primary_key: "uuid", column: "profile_uuid"
  end
end
