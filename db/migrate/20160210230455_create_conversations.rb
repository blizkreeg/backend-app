class CreateConversations < ActiveRecord::Migration
  def change
    create_table :conversations, id: false do |t|
      t.primary_key :id, :bigserial, null: false
      t.uuid :uuid, default: 'gen_random_uuid()', null: false
      t.jsonb :properties, null: false, default: '{}'
      t.string :state, null: false
      t.jsonb :state_properties, null: false, default: '{}'
      t.timestamps null: false
    end

    add_index :conversations, :uuid

    reversible do |dir|
      dir.up do
        execute "CREATE INDEX idx_gin_conversations ON conversations USING GIN(properties jsonb_path_ops);"
      end

      dir.down do
        execute "DROP INDEX idx_gin_conversations;"
      end
    end
  end
end
