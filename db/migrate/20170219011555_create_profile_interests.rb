class CreateProfileInterests < ActiveRecord::Migration
  def change
    create_table :profile_interests do |t|
      t.uuid :profile_uuid, null: false
      t.references :interest, index: true, foreign_key: true
      t.timestamps null: false
    end

    add_foreign_key :profile_interests, :profiles, primary_key: "uuid", column: "profile_uuid"

    add_index :profile_interests, :profile_uuid
  end
end
