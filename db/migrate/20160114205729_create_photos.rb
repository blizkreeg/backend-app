class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.jsonb :properties, null: false, default: '{}'
      t.uuid :profile_uuid, null: false

      t.timestamps null: false
    end

    add_foreign_key :photos, :profiles, primary_key: 'uuid', column: 'profile_uuid'
  end
end
