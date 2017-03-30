class CreateIntroductionRequests < ActiveRecord::Migration
  def change
    create_table :introduction_requests do |t|
      t.jsonb :properties, null: false, default: '{}'
      t.uuid :by_profile_uuid, null: false
      t.uuid :to_profile_uuid, null: false

      t.timestamps null: false
    end

    add_foreign_key :introduction_requests, :profiles, column: 'by_profile_uuid', primary_key: 'uuid'
    add_foreign_key :introduction_requests, :profiles, column: 'to_profile_uuid', primary_key: 'uuid'

    add_index :introduction_requests, :by_profile_uuid
    add_index :introduction_requests, :to_profile_uuid
  end
end
