module ProfileIntroductionsHelper

  extend ActiveSupport::Concern

  REFRESH_INTRODUCTIONS_IN = 24.hours

  def intros_generated_at
    $redis.get("generated_intros_ts:#{self.uuid}").to_i
  end

  def intros_generated_at=(time)
    $redis.set("generated_intros_ts:#{self.uuid}", time.to_i)
  end

  def intros_expire_at
    self.intros_generated_at + REFRESH_INTRODUCTIONS_IN
  end

  def has_current_intros?
    (self.intros_generated_at > 0) && self.current_intros_profile_uuids.present?
  end

  # Do we need to generate new intros for this profile?
  def needs_intros?
    # time to generate new intros
    if self.has_current_intros?
      Time.now.utc.to_i >= self.intros_expire_at
    else
      # no current intros
      true
    end
  end

  def checked_intros_at
    $redis.get("visited_intros_ts:#{self.uuid}").to_i
  end

  def checked_intros_at=(time)
    $redis.set("visited_intros_ts:#{self.uuid}", time.to_i)
  end

  def current_intros_profiles
    self.current_intros_profile_uuids.map { |uuid| Profile.find(uuid) rescue nil }.compact
  end

  def current_intros_profiles=(profiles)
    self.current_intros_profile_uuids = profiles.map(&:uuid)
  end

  def current_intros_profile_uuids
    JSON.parse($redis.get("generated_intro_profiles:#{self.uuid}")) || []
  end

  def current_intros_profile_uuids=(uuids)
    $redis.set("generated_intro_profiles:#{self.uuid}", uuids.to_json)
  end

  def intros_refreshed_at
    self.intros_generated_at > 0 ? [Time.at(self.intros_expire_at), (Time.now + REFRESH_INTRODUCTIONS_IN)].min : (Time.now + REFRESH_INTRODUCTIONS_IN)
  end

  def skip_stale_intros
    return if self.current_intros_profile_uuids.blank?

    self.current_intros_profile_uuids.each do |uuid|
      next unless Profile.exists?(uuid)

      SkippedProfile.find_or_create_by!(by_profile_uuid: self.uuid, skipped_profile_uuid: uuid)
    end
  end

  def has_more_intros?
    skip_uuids_in_matching = self.current_intros_profile_uuids

    Matchmaker.introduction_suggestions_for(self, skip_uuids_in_matching).present?
  end

  def sent_reminder_at
    t = $redis.get("intros_reminder_at:#{self.uuid}")
    t.nil? ? nil : Time.at(t.to_i)
  end

  def sent_reminder_at=(time)
    $redis.set("intros_reminder_at:#{self.uuid}", time.to_i)
  end

  def needs_reminder?
    self.sent_reminder_at.blank? ||
    (Time.now.utc >= (self.sent_reminder_at + 24.hours))
  end

end
