class Conversation < ActiveRecord::Base
  include ConversationStateMachine

  has_many :messages, autosave: true, dependent: :destroy

  CLOSE_TIME = 7.days

  ATTRIBUTES = {
    participant_uuids: :string_array,
    closes_at: :date_time,
    open: :boolean,
  }

  jsonb_accessor :properties, ATTRIBUTES

  before_create :set_defaults

  def fresh?
    self.messages.count == 0
  end

  # who is supposed to start the conv?
  def initiator
    p1_uuid = self.participant_uuids.first
    p2_uuid = self.participant_uuids.second

    if Match.where(initiates_profile_uuid: p1_uuid, matched_profile_uuid: p2_uuid).take.present?
      Profile.find(p1_uuid)
    elsif Match.where(initiates_profile_uuid: p2_uuid, matched_profile_uuid: p1_uuid).take.present?
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

  def the_other_who_is_not(not_uuid)
    other_uuid = (self.participant_uuids - [not_uuid]).first
    Profile.find(other_uuid)
  end

  def open!
    self.open = true
    self.closes_at = DateTime.now + CLOSE_TIME
    self.save!

    # send both into chat state
    self.participants.map { |participant| participant.conversation_mode!(:in_conversation, 'URL') } # TBD: FILL IN URL!!!
  end

  def close!
    self.open = false
    self.save!
  end

  private

  def set_defaults
    self.open = false

    true
  end
end
