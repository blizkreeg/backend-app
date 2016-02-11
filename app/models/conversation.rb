class Conversation < ActiveRecord::Base
  has_many :messages, autosave: true, dependent: :destroy

  ATTRIBUTES = {
    participant_uuids: :string_array,
    closes_at: :date_time
  }

  jsonb_accessor :properties, ATTRIBUTES
end
