class Message < ActiveRecord::Base
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

  jsonb_accessor :properties, ATTRIBUTES

  before_save :set_defaults

  def sent_at
    self.created_at
  end

  private

  def set_defaults
    self.read = false if self.read.nil?

    true
  end
end
