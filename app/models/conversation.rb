class Conversation < ActiveRecord::Base
  include ConversationStateMachine
  include FirebaseConversationHelper

  has_many :messages, autosave: true, dependent: :destroy

  CLOSE_TIME = 7.days
  CLOSED_BECAUSE_EXPIRED = 'Expired'
  CLOSED_BECAUSE_UNMATCHED = 'Unmatched'

  RADIO_SILENCE_DELAY = 16.hours
  HEALTH_CHECK_DELAY = 24.hours
  READY_TO_MEET_DELAY = 48.hours
  CHECK_IF_MEETING_DELAY = 48.hours
  CLOSE_NOTICE_DELAY = 24.hours

  ATTRIBUTES = {
    participant_uuids: :string_array,
    opened_at: :date_time,
    closes_at: :date_time,
    open: :boolean,
    closed_reason: :string,
    closed_by_uuid: :string,
    closed_at: :date_time
  }

  jsonb_accessor :properties, ATTRIBUTES

  def self.find_or_create_by_participants!(between_uuids)
    with_participant_uuids(between_uuids).take || create!(participant_uuids: between_uuids)
  end

  def self.expire_conversation(id)
    conv = Conversation.find(id) rescue nil
    return if conv.blank?
    conv.close! if conv.open

    conv.participants.each do |participant|
      participant.conversation_expired!(:waiting_for_matches) if participant.in_conversation?
    end
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

    initialize_firebase

    # Conversation.delay_for(HEALTH_CHECK_DELAY).move_conversation_to(self.id, 'health_check')
    # Conversation.delay_until(self.closes_at).expire_conversation(self.id)
  end

  # close when the conversation expires
  def close!(closed_by_uuid=nil)
    self.open = false
    self.closed_reason = closed_by_uuid.blank? ? CLOSED_BECAUSE_EXPIRED : CLOSED_BECAUSE_UNMATCHED
    self.closed_by_uuid = closed_by_uuid
    self.closed_at = DateTime.now.utc
    self.save!
  end

  def add_message!(content, sender_uuid)
    if content.present?
      message = Message.new(content: content, sender_uuid: sender_uuid, recipient_uuid: self.the_other_who_is_not(sender_uuid).uuid)
      self.messages.push(message)
      self.save!
    end
  end
end
