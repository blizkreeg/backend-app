class CreateDatePlaces < ActiveRecord::Migration
  def change
    create_table :date_places do |t|
      t.jsonb :properties, default: {}
      t.timestamps null: false
    end
  end
end
