class Match < ActiveRecord::Base
  # include JsonbAttributeHelpers

  # who is the match for?
  belongs_to :for_profile, foreign_key: "for_profile_uuid", class_name: 'Profile'
  # who is the match?
  belongs_to :matched_profile, foreign_key: "matched_profile_uuid", class_name: 'Profile'

  STALE_EXPIRATION_DURATION = 2910.minutes # 48 hours, 30 minutes
  LIKE_DECISION_STR = 'Like'
  PASS_DECISION_STR = 'Pass'

  scope :undecided, -> { with_decision(nil) }
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
    active: :boolean
  }

  # store_accessor :properties, *(ATTRIBUTES.keys.map(&:to_sym))
  # jsonb_attr_helper :properties, ATTRIBUTES
  jsonb_accessor :properties, ATTRIBUTES

  validates :unmatched_reason, inclusion: { in: Constants::UNMATCH_REASONS, message: "%{value} is not a valid reason" }, allow_nil: true

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

  def unmatch!(reason)
    # TBD: when unmatching one side, what about the other? what effects will that case if left unmatched?
    self.unmatched = true
    self.unmatched_at = DateTime.now
    self.unmatched_reason = reason
    EKC.logger.error "Unmatching on a match that is not active! match id: #{self.id}" if !self.active
    self.active = false
    self.save!
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
    self.expires_at > DateTime.now ? ((self.expires_at.to_i - DateTime.now.utc.to_i) / 1.hour) : 0
  end

  private

  def set_defaults
    self.unmatched = false if self.unmatched.nil?
    self.decision_at = DateTime.now if self.decision_changed?
    self.mutual = false if self.mutual.nil?
    self.active = false if self.active.nil?

    true
  end

  # def destroy_conversation
  #   self.conversation.destroy
  # end
end
