class CreateBrewCategories < ActiveRecord::Migration
  def change
    create_table :brew_categories do |t|
      t.jsonb :properties, null: false, default: '{}'

      t.timestamps null: false
    end
  end
end
