class CreateRealDates < ActiveRecord::Migration
  def change
    create_table :real_dates, id: false do |t|
      t.primary_key :id, :bigserial, null: false
      t.jsonb :properties, default: {}
      t.bigint :conversation_id, null: false
      t.uuid :profile_uuid, null: false
      t.integer :date_place_id
      t.timestamps null: false
    end

    add_index :real_dates, :conversation_id
    add_index :real_dates, :profile_uuid
    add_index :real_dates, :date_place_id

    add_foreign_key :real_dates, :conversations
    add_foreign_key :real_dates, :profiles, primary_key: "uuid", column: "profile_uuid"
    add_foreign_key :real_dates, :date_places
  end
end
