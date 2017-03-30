class CreateBrewings < ActiveRecord::Migration
  def change
    create_table :brewings do |t|
      t.uuid :profile_uuid, null: false
      t.integer :brew_id, null: false
      t.jsonb :properties, null: false, default: '{}'

      t.timestamps null: false
    end

    add_foreign_key :brewings, :profiles, primary_key: "uuid", column: "profile_uuid"
    add_foreign_key :brewings, :brews

    add_index :brewings, :profile_uuid
    add_index :brewings, :brew_id
  end
end
