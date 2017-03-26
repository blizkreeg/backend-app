class CreateSkippedProfiles < ActiveRecord::Migration
  def change
    create_table :skipped_profiles do |t|
      t.jsonb :properties, null: false, default: '{}'
      t.uuid :by_profile_uuid, null: false
      t.uuid :skipped_profile_uuid, null: false

      t.timestamps null: false
    end

    add_foreign_key :skipped_profiles, :profiles, column: 'by_profile_uuid', primary_key: 'uuid'
    add_foreign_key :skipped_profiles, :profiles, column: 'skipped_profile_uuid', primary_key: 'uuid'

    add_index :skipped_profiles, :by_profile_uuid
    add_index :skipped_profiles, :skipped_profile_uuid
  end
end
