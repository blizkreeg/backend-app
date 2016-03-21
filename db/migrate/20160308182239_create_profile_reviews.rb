class CreateProfileReviews < ActiveRecord::Migration
  def change
    create_table :profile_reviews do |t|
      t.uuid :profile_uuid, null: false
      t.jsonb :properties, default: {}, null: false
      t.timestamps null: false
    end

    add_index :profile_reviews, :profile_uuid

    add_foreign_key :profile_reviews, :profiles, primary_key: "uuid", column: "profile_uuid"
  end
end
