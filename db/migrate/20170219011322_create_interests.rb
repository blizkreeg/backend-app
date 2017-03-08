class CreateInterests < ActiveRecord::Migration
  def change
    create_table :interests do |t|
      t.jsonb :properties, null: false, default: '{}'
      t.timestamps null: false
    end
  end
end
