class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.jsonb :properties, null: false, default: '{}'

      t.timestamps null: false
    end
  end
end
