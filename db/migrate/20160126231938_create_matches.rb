class CreateMatches < ActiveRecord::Migration
  def change
    create_table :matches, id: false do |t|
      t.primary_key :id, :bigserial, null: false
      t.uuid :for_profile_uuid, null: false
      t.uuid :matched_profile_uuid, null: false
      t.jsonb :properties, null: false, default: '{}'

      t.timestamps null: false
    end

    add_foreign_key :matches, :profiles, column: 'for_profile_uuid', primary_key: 'uuid'
    add_foreign_key :matches, :profiles, column: 'matched_profile_uuid', primary_key: 'uuid'

    add_index :matches, :for_profile_uuid
    add_index :matches, :matched_profile_uuid
  end
end
