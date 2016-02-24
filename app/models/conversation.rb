class Conversation < ActiveRecord::Base
  include ConversationStateMachine

  has_many :messages, autosave: true, dependent: :destroy

  CLOSE_TIME = 7.days

  ATTRIBUTES = {
    participant_uuids: :string_array,
    opened_at: :date_time,
    closes_at: :date_time,
    open: :boolean
  }

  jsonb_accessor :properties, ATTRIBUTES

  before_create :set_defaults

  def self.find_or_create_by_participants!(between_uuids)
    with_participant_uuids(between_uuids).take || create!(participant_uuids: between_uuids)
  end

  def fresh?
    self.messages.count == 0
  end

  # who is supposed to start the conv?
  def initiator
    p1_uuid = self.participant_uuids.first
    p2_uuid = self.participant_uuids.second

    if Match.where("properties->>'initiates_profile_uuid' = '#{p1_uuid}' AND matched_profile_uuid = '#{p2_uuid}'").take.present?
      Profile.find(p1_uuid)
    elsif Match.where("properties->>'initiates_profile_uuid' = '#{p2_uuid}' AND matched_profile_uuid = '#{p1_uuid}'").take.present?
      Profile.find(p2_uuid)
    end
  end

  # the one that is supposed to respond to the starter
  def responder
    other_uuid = (self.participant_uuids - [self.initiator.uuid]).first
    Profile.find(other_uuid)
  end

  def participants
    self.participant_uuids.map { |uuid| Profile.find(uuid) }
  end

  # the other participant
  def the_other_who_is_not(not_uuid)
    other_uuid = (self.participant_uuids - [not_uuid]).first
    Profile.find(other_uuid)
  end

  # open chat line
  def open!
    self.open = true
    self.opened_at = DateTime.now.utc
    self.closes_at = self.opened_at + CLOSE_TIME
    self.save!

    initiator_match = Match.where("properties->>'initiates_profile_uuid' = '#{self.initiator.uuid}' AND matched_profile_uuid = '#{self.responder.uuid}'").take

    # send both into chat state
    self.participants.each do |participant|
      am_i_initiator = (self.initiator.uuid == participant.uuid)
      match = am_i_initiator ? initiator_match : initiator_match.reverse
      profile_uuid = am_i_initiator ? self.initiator.uuid : self.responder.uuid

      participant.conversation_mode!(:in_conversation,
                                      Rails.application.routes.url_helpers.v1_profile_match_path(profile_uuid, match.id))
    end

    $firebase_conversations.set("#{self.uuid}/metadata", { participant_uuids: self.participant_uuids,
                                                            opened_at: self.opened_at.iso8601,
                                                            closes_at: self.closes_at.iso8601 })
    self.push_messages_to_firebase
  end

  # close when the conversation expires
  def close!
    self.open = false
    self.save!
  end

  def append_message!(content, sender_uuid)
    if content.present?
      message = Message.new(content: content, sender_uuid: sender_uuid, recipient_uuid: self.the_other_who_is_not(sender_uuid).uuid)
      self.messages.push(message)
      self.save!
    end
  end

  def push_messages_to_firebase
    self.messages.each do |message|
      $firebase_conversations.push(self.firebase_messages_endpoint, message.firebase_json)
    end
  end

  def firebase_messages_endpoint
    "#{self.uuid}/messages"
  end

  private

  def set_defaults
    self.open = false

    true
  end
end
