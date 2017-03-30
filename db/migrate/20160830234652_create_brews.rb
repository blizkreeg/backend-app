class CreateBrews < ActiveRecord::Migration
  def change
    create_table :brews do |t|
      t.jsonb :properties, null: false, default: '{}'

      t.timestamps null: false
    end
  end
end
