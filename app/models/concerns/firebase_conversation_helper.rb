module FirebaseConversationHelper
  extend ActiveSupport::Concern

  def initialize_firebase
    $firebase_conversations.set(self.firebase_metadata_endpoint, self.firebase_metadata({open: true}))
    sync_messages_to_firebase
  end

  def sync_messages_to_firebase
    self.messages.each do |message|
      $firebase_conversations.push(self.firebase_messages_endpoint, message.firebase_json)
    end
  end

  def close_conversation_firebase
    $firebase_conversations.set(self.firebase_metadata_endpoint, self.firebase_metadata({open: false}))
  end

  def firebase_messages_endpoint
    "#{self.uuid}/messages"
  end

  def firebase_metadata_endpoint
    "#{self.uuid}/metadata"
  end

  def firebase_metadata(override_options = {})
    opened_at = self.opened_at.present? ? self.opened_at.strftime('%Q') : nil
    closes_at = self.closes_at.present? ? self.closes_at.strftime('%Q') : nil
    {
      participant_uuids: self.participant_uuids,
      "#{self.initiator.uuid}_firstname": self.initiator.firstname,
      "#{self.responder.uuid}_firstname": self.responder.firstname,
      opened_at: opened_at,
      closes_at: closes_at,
      open: nil
    }.merge(override_options)
  end
end
