class AddGeoSearchToProfiles < ActiveRecord::Migration
  def change
    change_table :profiles do |t|
      t.decimal :search_lat, precision: 7, scale: 4
      t.decimal :search_lng, precision: 7, scale: 4
    end

    reversible do |dir|
      dir.up do
        execute "CREATE EXTENSION cube;"
        execute "CREATE EXTENSION earthdistance;"

        execute "UPDATE PROFILES SET search_lat = CAST(properties->>'latitude' AS decimal);"
        execute "UPDATE PROFILES SET search_lng = CAST(properties->>'longitude' AS decimal);"

        execute "CREATE INDEX idx_profiles_location_search on profiles USING gist(ll_to_earth(search_lat, search_lng));"
      end

      dir.down do
        execute "DROP INDEX idx_profiles_location_search;"
        execute "DROP EXTENSION earthdistance;"
        execute "DROP EXTENSION cube;"
      end
    end
  end
end
