module Matchmaker

  DEFAULT_AGE_GAP_MEN   = [-5, 0]
  DEFAULT_AGE_GAP_WOMEN = [0, +5]

  DEFAULT_HEIGHT_GAP_MEN    = [-7, 0]
  DEFAULT_HEIGHT_GAP_WOMEN  = [0, +7]

  N_MATCHES_AT_A_TIME = 5

  module_function

  def generate_new_matches_for(profile_uuid)
    profile = Profile.find(profile_uuid)

    new_match_uuids = Matchmaker.new_eligible_matches(profile).pluck(:uuid)

    # TBD: compute scores
    scores = Array.new(new_match_uuids.size, 1)

    $redis.zadd("new_matches/#{profile.uuid}", scores.product(new_match_uuids).flatten)

    profile.update!(has_new_matches: true)
  rescue ActiveRecord::RecordNotFound
    EKC.logger.error "#{self.class.name.to_s}##{__method__.to_s}: Profile #{profile_uuid} appears to have been deleted!"
  end

  def create_between(p1_uuid, p2_uuid)
    profile_one = Profile.find p1_uuid
    profile_two = Profile.find p2_uuid

    initiator_uuid = profile_one.male? ? profile_one.uuid : profile_two.uuid

    match_1 = Match.create_with(initiates_profile_uuid: initiator_uuid)
                      .find_or_create_by(for_profile_uuid: profile_one.uuid, matched_profile_uuid: profile_two.uuid)
    match_2 = Match.create_with(initiates_profile_uuid: initiator_uuid)
                      .find_or_create_by(for_profile_uuid: profile_two.uuid, matched_profile_uuid: profile_one.uuid)

    [match_1, match_2]
  end

  def create_matches(profile_uuid, match_uuids)
    profile = Profile.find(profile_uuid)

    match_uuids.each do |match_uuid|
      create_between(profile.uuid, match_uuid)
    end

    case profile.state
    when 'waiting_for_matches'
      profile.new_matches!(:has_matches)
    when 'waiting_for_matches_and_response'
      profile.new_matches!(:has_matches_and_waiting_for_response)
    end
  end

  def create_conversation(between_uuids=[])
    Conversation.find_or_create_by_participants!(between_uuids)
  end

  def new_eligible_matches(profile, opts = {})
    existing_matches = profile.matches.to_sql

    Profile
      .active
      .older_than(profile.seeking_minimum_age)
      .younger_than(profile.seeking_maximum_age)
      .taller_than(profile.seeking_minimum_height_in)
      .shorter_than(profile.seeking_maximum_height_in)
      .of_faiths(profile.seeking_faith)
      .of_gender(profile.seeking_gender)
      .joins("LEFT OUTER JOIN (#{existing_matches}) matches ON matches.matched_profile_uuid = profiles.uuid")
      .where(matches: { matched_profile_uuid: nil })
      .limit(opts[:limit] || N_MATCHES_AT_A_TIME)
  end

  def default_min_age_pref(gender, age)
    age_gap_lower = gender == Profile::GENDER_MALE ? Matchmaker::DEFAULT_AGE_GAP_MEN.first : Matchmaker::DEFAULT_AGE_GAP_WOMEN.first
    age_gap_upper = gender == Profile::GENDER_MALE ? Matchmaker::DEFAULT_AGE_GAP_MEN.second : Matchmaker::DEFAULT_AGE_GAP_WOMEN.second

    [age + age_gap_lower, Constants::MIN_AGE].min
  end

  def default_max_age_pref(gender, age)
    age_gap_lower = gender == Profile::GENDER_MALE ? Matchmaker::DEFAULT_AGE_GAP_MEN.first : Matchmaker::DEFAULT_AGE_GAP_WOMEN.first
    age_gap_upper = gender == Profile::GENDER_MALE ? Matchmaker::DEFAULT_AGE_GAP_MEN.second : Matchmaker::DEFAULT_AGE_GAP_WOMEN.second

    age + age_gap_upper
  end

  def default_min_ht_pref(gender, height)
    height_gap_lower = gender == Profile::GENDER_MALE ? Matchmaker::DEFAULT_HEIGHT_GAP_MEN.first : Matchmaker::DEFAULT_HEIGHT_GAP_WOMEN.first
    height_gap_upper = gender == Profile::GENDER_MALE ? Matchmaker::DEFAULT_HEIGHT_GAP_MEN.second : Matchmaker::DEFAULT_HEIGHT_GAP_WOMEN.second

    Constants::HEIGHT_RANGE[[(Constants::HEIGHT_RANGE.index(height) + height_gap_lower), 0].max]
  end

  def default_max_ht_pref(gender, height)
    height_gap_lower = gender == Profile::GENDER_MALE ? Matchmaker::DEFAULT_HEIGHT_GAP_MEN.first : Matchmaker::DEFAULT_HEIGHT_GAP_WOMEN.first
    height_gap_upper = gender == Profile::GENDER_MALE ? Matchmaker::DEFAULT_HEIGHT_GAP_MEN.second : Matchmaker::DEFAULT_HEIGHT_GAP_WOMEN.second

    Constants::HEIGHT_RANGE[[(Constants::HEIGHT_RANGE.index(height) + height_gap_upper), Constants::HEIGHT_RANGE.size-1].min]
  end

  def default_faith_pref
    Constants::FAITHS
  end
end
