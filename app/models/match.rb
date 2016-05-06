class Match < ActiveRecord::Base
  # include JsonbAttributeHelpers

  # who is the match for?
  belongs_to :for_profile, foreign_key: "for_profile_uuid", class_name: 'Profile'
  # who is the match?
  belongs_to :matched_profile, foreign_key: "matched_profile_uuid", class_name: 'Profile'

  STALE_EXPIRATION_DURATION = 2910.minutes # 48 hours, 30 minutes
  LIKE_DECISION_STR = 'Like'
  PASS_DECISION_STR = 'Pass'
  UNMATCH_REASONS = {
    exchanged_numbers: "We already exchanged numbers",
    lost_interest: "Not interested anymore",
    inappropriate: "Inappropriate behavior/talk",
    spam: "Feels like spam",
    noreply: "Not getting replies",
    conversation_not_started: "Didn't start conversation", # TBD: run a timer to set unmatched=true and reason to this if time.now > expires_at
    conversation_not_responded: "Didn't respond",
    conversation_done: "Completed conversation", # TBD: when conversation is done/expired, set this
    other_side_unmatched: "Other person unmatched"
  }

  scope :undecided, -> { with_decision(nil).order("CAST(matches.properties->>'quality_score' AS decimal) ASC NULLS LAST") }
  scope :closed, -> { with_unmatched(true) }
  scope :queued, -> { with_unmatched(false) }
  scope :mutual, -> { queued.with_mutual(true) }
  scope :liked, -> { with_decision(LIKE_DECISION_STR) }
  scope :passed, -> { with_decision(PASS_DECISION_STR) }
  scope :active, -> { with_active(true) }

  MASS_UPDATE_ATTRIBUTES = %i(
    decision
  )

  ATTRIBUTES = {
    decision: :string,
    decision_at: :date_time,
    delivered_at: :date_time,
    unmatched: :boolean,
    unmatched_at: :date_time,
    unmatched_reason: :string,
    expires_at: :date_time,
    initiates_profile_uuid: :string,
    mutual: :boolean,
    active: :boolean,
    quality_score: :decimal, # value between 0 and 1, 0 = as good as it gets, 1 = ...
  }

  # store_accessor :properties, *(ATTRIBUTES.keys.map(&:to_sym))
  # jsonb_attr_helper :properties, ATTRIBUTES
  jsonb_accessor :properties, ATTRIBUTES

  validates :unmatched_reason, inclusion: { in: UNMATCH_REASONS.values, message: "%{value} is not a valid reason" }, allow_nil: true

  before_save :set_defaults
  # after_destroy :destroy_conversation

  def self.update_delivery_time(id)
    Match.update(id, delivered_at: DateTime.now)
  end

  def self.enable_mutual_flag_and_create_conversation!(match_ids)
    matches = Match.find match_ids
    matches.each do |match|
      reverse_match = match.reverse
      if reverse_match.present? && reverse_match.like?
        match.update(mutual: true)
        reverse_match.update(mutual: true)

        Conversation.find_or_create_by_participants!([match.for_profile.uuid, match.matched_profile.uuid])
      end
    end
  end

  def self.check_match_expiration(id, for_profile_uuid)
    begin
      match = Match.find(id)
    rescue ActiveRecord::RecordNotFound
      EKC.logger.error "Match #{id} not found when checking for expiration."
      return
    end

    if match.initiates_profile_uuid == for_profile_uuid
      if match.conversation.messages.count == 0
        # close the match - it has expired
        match.unmatch!(UNMATCH_REASONS[:conversation_not_started])
      end
    else
      if !match.conversation.open
        # close the match - the other person didn't respond
        match.unmatch!(UNMATCH_REASONS[:conversation_not_responded])
      end
    end
  end

  def unmatch!(reason)
    if !self.active
      EKC.logger.error "Got request to unmatch on match that is not active! match id: #{self.id}"
      return
    end

    # update my match state
    self.update!(unmatched: true, unmatched_at: DateTime.now, unmatched_reason: reason, active: false)

    # if the user was in a conversation, close it and move the conversation state to silence
    if self.conversation.open
      self.conversation.close!(self.for_profile_uuid)
      if reason == UNMATCH_REASONS[:exchanged_numbers]
        Conversation.delay_for(Conversation::NUMBER_EXCHANGE_UNMATCH_DELAY).move_conversation_to(self.conversation.id, 'radio_silence')
      else
        Conversation.delay_for(Conversation::RADIO_SILENCE_DELAY).move_conversation_to(self.conversation.id, 'radio_silence')
      end
    else
      # if the other person has not already unmatched and moved on to someone else update their state
      reverse_match = self.reverse
      if reverse_match.id == reverse.for_profile.try(:active_mutual_match).try(:id)
        case self.matched_profile.state.to_sym
        when :mutual_match
          self.matched_profile.unmatch!(:waiting_for_matches)
        when :waiting_for_matches_and_response
          self.matched_profile.unmatch!(:waiting_for_matches)
        when :has_matches_and_waiting_for_response
          self.matched_profile.unmatch!(:has_matches)
        when :show_matches_and_waiting_for_response
          self.matched_profile.unmatch!(:show_matches)
        end
      end
      unless self.reverse.unmatched
        self.reverse.update!(unmatched: true, unmatched_at: DateTime.now, unmatched_reason: UNMATCH_REASONS[:other_side_unmatched], active: false)
      end
    end

    self.for_profile.unmatch!(:waiting_for_matches)

    ProfileEventLogWorker.perform_async(self.for_profile_uuid, :unmatched_on, uuid: self.matched_profile_uuid)
    ProfileEventLogWorker.perform_async(self.matched_profile_uuid, :got_unmatched, uuid: self.for_profile_uuid)
  rescue StandardError => e
    EKC.logger.error "Error while unmatching: #{e.message}\n#{e.backtrace.join('\n')}"
  end

  def reverse
    Match.where(for_profile_uuid: self.matched_profile_uuid, matched_profile_uuid: self.for_profile_uuid).take
  end

  def conversation
    Conversation.with_participant_uuids([self.for_profile_uuid, self.matched_profile_uuid]).take
  end

  def like?
    self.decision == LIKE_DECISION_STR
  end

  def pass?
    self.decision == PASS_DECISION_STR
  end

  def undecided?
    self.decision.nil?
  end

  def waiting_for_response_expires_in_hours
    self.reverse.expires_in_hours rescue nil
  end

  def test_and_set_expiration!
    self.update!(expires_at: (DateTime.now.utc + STALE_EXPIRATION_DURATION)) if self.expires_at.nil?
  end

  def expires_in_hours
    if self.expires_at.present?
      self.expires_at > DateTime.now ? ((self.expires_at.to_i - DateTime.now.utc.to_i) / 1.hour) : 0
    else
      nil
    end
  end

  private

  def set_defaults
    self.unmatched = false if self.unmatched.nil?
    self.decision_at = DateTime.now if self.decision_changed?
    self.mutual = false if self.mutual.nil?
    self.active = false if self.active.nil?
    self.quality_score ||= 0.7

    true
  end

  # def destroy_conversation
  #   self.conversation.destroy
  # end
end
