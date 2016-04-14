module FirebaseConversationHelper
  extend ActiveSupport::Concern

  def initialize_firebase
    $firebase_conversations.set(self.firebase_metadata_endpoint, { participant_uuids: self.participant_uuids,
                                                                    opened_at: self.opened_at.try(:iso8601),
                                                                    closes_at: self.closes_at.try(:iso8601),
                                                                    open: true })
    sync_messages_to_firebase
  end

  def sync_messages_to_firebase
    self.messages.each do |message|
      $firebase_conversations.push(self.firebase_messages_endpoint, message.firebase_json)
    end
  end

  def close_conversation_firebase
    $firebase_conversations.set(self.firebase_metadata_endpoint, { participant_uuids: self.participant_uuids,
                                                                    opened_at: self.opened_at.try(:iso8601),
                                                                    closes_at: self.closes_at.try(:iso8601),
                                                                    open: false })
  end

  def firebase_messages_endpoint
    "#{self.uuid}/messages"
  end

  def firebase_metadata_endpoint
    "#{self.uuid}/metadata"
  end
end
