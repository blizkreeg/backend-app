class CreateConversationHealths < ActiveRecord::Migration
  def change
    create_table :conversation_healths, id: false do |t|
      t.primary_key :id, :bigserial, null: false
      t.jsonb :properties, default: {}
      t.bigint :conversation_id, null: false
      t.uuid :profile_uuid, null: false
      t.datetime :recorded_at, null: false
      t.timestamps null: false
    end

    add_index :conversation_healths, :conversation_id
    add_index :conversation_healths, :profile_uuid

    add_foreign_key :conversation_healths, :conversations
    add_foreign_key :conversation_healths, :profiles, primary_key: "uuid", column: "profile_uuid"
  end
end
