class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages, id: false do |t|
      t.primary_key :id, :bigserial, null: false
      t.integer :conversation_id, limit: 8, null: false
      t.uuid :sender_uuid, null: false
      t.uuid :recipient_uuid, null: false
      t.jsonb :properties, null: false, default: '{}'
      t.timestamps null: false
    end

    add_foreign_key :messages, :conversations
    add_foreign_key :messages, :profiles, primary_key: "uuid", column: "sender_uuid"
    add_foreign_key :messages, :profiles, primary_key: "uuid", column: "recipient_uuid"

    add_index :messages, :conversation_id
    add_index :messages, :sender_uuid
    add_index :messages, :recipient_uuid
  end
end
