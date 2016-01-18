class CreateProfileAuthentications < ActiveRecord::Migration
  def change
    create_table :profile_authentications do |t|
      t.string :uid
      t.string :type
      t.string :token
      t.string :token_expiration
      t.jsonb :auth_hash
      t.uuid :profile_uuid, null: false

      t.timestamps null: false
    end

    add_foreign_key :profile_authentications, :profiles, primary_key: "uuid", column: "profile_uuid"
  end
end
