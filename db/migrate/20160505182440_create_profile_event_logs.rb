class CreateProfileEventLogs < ActiveRecord::Migration
  def change
    create_table :profile_event_logs do |t|
      t.uuid :profile_uuid, null: false
      t.string :event_name, null: false
      t.jsonb :properties, default: {}, null: false
      t.timestamps null: false
    end

    add_foreign_key :profile_event_logs, :profiles, primary_key: "uuid", column: "profile_uuid"
    add_index :profile_event_logs, :profile_uuid
    add_index :profile_event_logs, :event_name
  end
end
