class Message < ActiveRecord::Base
  # include JsonbAttributeHelpers

  belongs_to :sender, foreign_key: "sender_uuid"
  belongs_to :recipient, foreign_key: "recipient_uuid"
  belongs_to :conversation

  LIMIT_N_MESSAGES = 10

  default_scope { order('created_at DESC') }

  ATTRIBUTES = {
    content: :string,
    read: :boolean,
    read_at: :date_time
  }

  # store_accessor :properties, *(ATTRIBUTES.keys.map(&:to_sym))
  # jsonb_attr_helper :properties, ATTRIBUTES
  jsonb_accessor :properties, ATTRIBUTES

  before_save :set_defaults

  def sent_at
    self.created_at
  end

  def firebase_json
    {
      sender_uuid: self.sender_uuid,
      recipient_uuid: self.recipient_uuid,
      content: self.content,
      sent_at: (Time.now.to_f * 1_000).to_i,
      ack: self.read
    }
  end

  private

  def set_defaults
    self.read = false if self.read.nil?

    true
  end
end
