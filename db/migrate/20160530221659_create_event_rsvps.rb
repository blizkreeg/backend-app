class CreateEventRsvps < ActiveRecord::Migration
  def change
    create_table :event_rsvps do |t|
      t.jsonb :properties, null: false, default: '{}'
      t.uuid :profile_uuid, null: false
      t.integer :event_id, null: false

      t.timestamps null: false
    end

    add_foreign_key :event_rsvps, :profiles, primary_key: "uuid", column: "profile_uuid"
    add_foreign_key :event_rsvps, :events

    add_index :event_rsvps, :profile_uuid
    add_index :event_rsvps, :event_id
  end
end
