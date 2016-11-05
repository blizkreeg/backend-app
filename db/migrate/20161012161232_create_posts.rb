class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.jsonb :properties, null: false, default: '{}'

      t.timestamps null: false
    end
  end
end
