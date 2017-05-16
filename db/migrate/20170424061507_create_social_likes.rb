class CreateSocialLikes < ActiveRecord::Migration
  def change
    create_table :social_likes do |t|
      t.jsonb :properties, null: false, default: '{}'
      t.uuid :profile_uuid, null: false
      t.references :social_update, index: true, foreign_key: true

      t.timestamps null: false
    end

    add_foreign_key :social_likes, :profiles, primary_key: "uuid", column: "profile_uuid"

    add_index :social_likes, :profile_uuid
  end
end
