class CreateSocialUpdates < ActiveRecord::Migration
  def change
    create_table :social_updates do |t|
      t.jsonb :properties, null: false, default: '{}'
      t.uuid :profile_uuid, null: false

      t.timestamps null: false
    end

    add_foreign_key :social_updates, :profiles, primary_key: "uuid", column: "profile_uuid"

    add_index :social_updates, :profile_uuid
  end
end
