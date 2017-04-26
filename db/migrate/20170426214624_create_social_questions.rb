class CreateSocialQuestions < ActiveRecord::Migration
  def change
    create_table :social_questions do |t|
      t.jsonb :properties, null: false, default: '{}'
      t.references :social_update, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
