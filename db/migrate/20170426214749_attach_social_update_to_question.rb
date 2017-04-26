class AttachSocialUpdateToQuestion < ActiveRecord::Migration
  def change
    change_table :social_updates do |t|
      t.references :social_question, index: true, foreign_key: true
    end
  end
end
