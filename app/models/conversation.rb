class Conversation < ActiveRecord::Base
  # include JsonbAttributeHelpers
  include ConversationStateMachine
  include FirebaseConversationHelper

  has_many :messages, autosave: true, dependent: :destroy
  has_many :conversation_healths, dependent: :destroy
  has_many :real_dates, dependent: :destroy
  has_many :date_suggestions, dependent: :destroy

  # Conversation Timeline
  # 00h:  OPEN
  # 24h:  how's it going?
  # 72h:  ready to meet? -> show dates (1h if both Y/Y)
  # 120h: check if meeting
  # 144h: close notice
  # 168h: CLOSE

  if Rails.application.config.test_mode
    RADIO_SILENCE_DELAY = 5.minutes
    HEALTH_CHECK_FROM_OPEN = 15.minutes
    READY_TO_MEET_FROM_OPEN = 3.hours
  else
    RADIO_SILENCE_DELAY = 16.hours
    HEALTH_CHECK_FROM_OPEN = 24.hours
    READY_TO_MEET_FROM_OPEN = 48.hours
  end

  NUMBER_EXCHANGE_UNMATCH_DELAY = 1.hour
  SHOW_DATE_SUGGESTIONS_DELAY = 10.minutes
  CHECK_IF_MEETING_FROM_OPEN = 120.hours
  CLOSE_NOTICE_FROM_OPEN = 144.hours
  CLOSE_TIME = 168.hours # 7.days

  OPENING_MESSAGE = "We’re happy to introduce you both! Say hello and ask something interesting :-)"
  CLOSING_MESSAGE = "We hope you have both exchanged numbers. This chat will close in 24 hours."
  CLOSED_BECAUSE_EXPIRED = 'Expired'
  CLOSED_BECAUSE_UNMATCHED = 'Unmatched'
  MAX_PARTICIPANTS = 2

  ATTRIBUTES = {
    participant_uuids: :string_array,
    opened_at: :date_time,
    closes_at: :date_time,
    open: :boolean,
    closed_reason: :string,
    closed_by_uuid: :string,
    closed_at: :date_time,
    message_waiting_for_uuids: :string_array,
    introduction_id: :integer # FIXME this should become a foreign key
  }

  # store_accessor :properties, *(ATTRIBUTES.keys.map(&:to_sym))
  # jsonb_attr_helper :properties, ATTRIBUTES
  jsonb_accessor :properties, ATTRIBUTES

  validates_length_of :conversation_healths, maximum: MAX_PARTICIPANTS
  validates_length_of :real_dates, maximum: MAX_PARTICIPANTS

  # UUID is generated post creation at the db level
  after_create :refresh

  def self.find_or_create_by_participants!(between_uuids, create_options={})
    with_participant_uuids(between_uuids).take || create!({ participant_uuids: between_uuids }.merge(create_options))
  end

  def self.set_message_waiting(uuid, for_profile_uuid)
    conversation = Conversation.where(uuid: uuid).take
    uuids = conversation.message_waiting_for_uuids || []
    uuids << for_profile_uuid
    conversation.update!(message_waiting_for_uuids: uuids.uniq)
  end

  def has_message_waiting_for?(profile_uuid)
    self.message_waiting_for_uuids.present? && self.message_waiting_for_uuids.include?(profile_uuid)
  end

  # -- not in use --
  # def self.expire_conversation(id)
  #   conv = Conversation.find(id)
  #   conv.close! if conv.open

  #   conv.participants.each do |participant|
  #     # are they still in the same conversation?
  #     if (participant.active_mutual_match.try(:conversation).try(:id) == id) && participant.in_conversation?
  #       participant.active_mutual_match.update!(unmatched: true,
  #                                               unmatched_at: DateTime.now,
  #                                               unmatched_reason: Match::UNMATCH_REASONS[:conversation_done],
  #                                               active: false)
  #       participant.unmatch!(:waiting_for_matches)
  #     end
  #   end
  # rescue ActiveRecord::RecordNotFound => e
  #   EKC.logger.error("Trying to expire a conversation that was not found! id: #{id}")
  # end

  def fresh?
    self.messages.count == 0
  end

  def closed?
    !self.open
  end

  def intro
    IntroductionRequest.find(self.introduction_id)
  end

  # who is supposed to start the conv?
  def initiator
    intro.by

    # -- not in use --
    # p1_uuid = self.participant_uuids.first
    # p2_uuid = self.participant_uuids.second

    # if Match.where("properties->>'initiates_profile_uuid' = '#{p1_uuid}' AND matched_profile_uuid = '#{p2_uuid}'").take.present?
    #   Profile.find(p1_uuid)
    # elsif Match.where("properties->>'initiates_profile_uuid' = '#{p2_uuid}' AND matched_profile_uuid = '#{p1_uuid}'").take.present?
    #   Profile.find(p2_uuid)
    # end
  end

  # the one that is supposed to respond to the starter
  def responder
    intro.to

    # -- not in use --
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
    # self.closes_at = self.opened_at + CLOSE_TIME
    # self.state = 'info'
    self.save!

    # -- not in use: there is no "conversation" state now (as of 3/28/2017) --
    # initiator_match = Match.where("properties->>'initiates_profile_uuid' = '#{self.initiator.uuid}' AND matched_profile_uuid = '#{self.responder.uuid}'").take
    #
    # # send both into chat state
    # self.participants.each do |participant|
    #   am_i_initiator = (self.initiator.uuid == participant.uuid)
    #   match = am_i_initiator ? initiator_match : initiator_match.reverse
    #   profile_uuid = am_i_initiator ? self.initiator.uuid : self.responder.uuid

    #   participant.conversation_mode!(:in_conversation,
    #                                   Rails.application.routes.url_helpers.v1_profile_match_path(profile_uuid, match.id))
    # end

    self.initialize_firebase
    $firebase_conversations.push(self.firebase_messages_endpoint, self.notice_message_hash(OPENING_MESSAGE))

    # -- not in use: old stuff when conversation was kept moving --
    # Queue up conversation state changes
    # Conversation.delay_for(HEALTH_CHECK_FROM_OPEN).move_conversation_to(self.id, 'health_check')
    # Conversation.delay_for(READY_TO_MEET_FROM_OPEN).move_conversation_to(self.id, 'ready_to_meet')
    # Conversation.delay_for(CHECK_IF_MEETING_FROM_OPEN).move_conversation_to(self.id, 'check_if_meeting')
    # Conversation.delay_for(CLOSE_NOTICE_FROM_OPEN).move_conversation_to(self.id, 'close_notice')
    # Conversation.delay_for(CLOSE_TIME).expire_conversation(self.id)

    # -- not in use: being notified in IntroductionRequest.accept --
    # # notify participants
    # self.participants.each do |participant|
    #   other = self.the_other_who_is_not(participant.uuid)
    #   PushNotifier.delay.record_event(participant.uuid, 'conv_open', match_name: other.firstname)
    #   ProfileEventLogWorker.perform_async(participant.uuid, :entered_into_conversation, uuid: other.uuid)
    # end
  end

  # close when the conversation expires
  def close!(closed_by_uuid=nil)
    self.update!(
      open: false,
      closed_reason: closed_by_uuid.blank? ? CLOSED_BECAUSE_EXPIRED : CLOSED_BECAUSE_UNMATCHED,
      closed_by_uuid: closed_by_uuid,
      closed_at: DateTime.now.utc
    )

    close_conversation_firebase
  end

  def add_message!(content, sender_uuid, message_type)
    if content.blank?
      EKC.logger.error("Trying to add empty message for conversation: #{c.id}, sender_uuid: #{sender_uuid}, message_type: #{message_type}")
      return
    end

    message = Message.new(message_type: message_type,
                          content: content,
                          sender_uuid: sender_uuid,
                          recipient_uuid: self.the_other_who_is_not(sender_uuid).uuid)
    self.messages.push(message)
  end

  def both_ready_to_meet?
    self.real_dates.are_ready_to_meet.count == MAX_PARTICIPANTS
  end

  def closes_at_str
    return '' if closes_at.blank?

    # TBD -- format this in the user's timezone
    "#{self.closes_at.day.ordinalize} #{self.closes_at.strftime('%b')} at #{self.closes_at.strftime('%k:%M%P')}"
  end

  def notice_message_hash(content)
    {
      message_type: Message::TYPE_NOTICE,
      sender_uuid: nil,
      recipient_uuid: nil,
      content: content,
      sent_at: (Time.now.to_f * 1_000).to_i,
      ack: nil
    }
  end

  private

  def refresh
    self.reload
  end
end
