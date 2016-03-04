class CreateDateSuggestions < ActiveRecord::Migration
  def change
    create_table :date_suggestions do |t|
      t.jsonb :properties, default: {}
      t.bigint :conversation_id, null: false
      t.integer :date_place_id, null: false
      t.timestamps null: false
    end

    add_index :date_suggestions, :date_place_id
    add_index :date_suggestions, :conversation_id

    add_foreign_key :date_suggestions, :date_places
    add_foreign_key :date_suggestions, :conversations
  end
end
