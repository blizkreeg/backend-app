class CreateProfiles < ActiveRecord::Migration
  def change
    enable_extension 'uuid-ossp'
    enable_extension 'pgcrypto'

    create_table :profiles, id: false do |t|
      t.uuid :uuid, default: 'gen_random_uuid()', null: false, primary_key: true
      t.jsonb :properties, null: false, default: '{}'
      t.string :state, null: false
      t.jsonb :state_properties, null: false, default: '{}'
      # the default: below kept creating a default value of 0, hence the CREATE SEQUENCE below
      # t.integer :id_serial, null: false #, default: "nextval('profiles_id_serial_seq')"

      t.timestamps null: false
    end

    # if we need to revive the id_serial
    # execute "CREATE SEQUENCE profiles_id_serial_seq; ALTER TABLE profiles ALTER COLUMN id_serial SET DEFAULT nextval('profiles_id_serial_seq');"

    add_index :profiles, :created_at
    add_index :profiles, :updated_at

    reversible do |dir|
      dir.up do
        execute "CREATE INDEX idx_gin_profiles ON profiles USING GIN(properties jsonb_path_ops);"
        # execute "CREATE INDEX profiles_email_idx ON profiles((properties->>'email')) WHERE (properties->>'email') IS NOT NULL;"
      end

      dir.down do
        execute "DROP INDEX idx_gin_profiles;"
        # execute "DROP INDEX IF EXISTS profiles_email_idx;"
      end
    end
  end
end
