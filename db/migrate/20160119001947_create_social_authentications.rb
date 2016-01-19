class CreateSocialAuthentications < ActiveRecord::Migration
  def change
    create_table :social_authentications do |t|
      t.string :oauth_uid
      t.string :oauth_provider
      t.string :oauth_token
      t.string :oauth_token_expiration
      t.jsonb :oauth_hash
      t.uuid :profile_uuid, null: false

      t.timestamps null: false
    end

    add_foreign_key :social_authentications, :profiles, primary_key: "uuid", column: "profile_uuid"

    add_index :social_authentications, [:oauth_provider, :oauth_uid], unique: true
    add_index :social_authentications, :profile_uuid
  end
end
