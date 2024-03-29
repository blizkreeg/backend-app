module Matchmaker

  DEFAULT_AGE_GAP_MEN   = [-6, +1]
  DEFAULT_AGE_GAP_WOMEN = [-1, +6]

  DEFAULT_HEIGHT_GAP_MEN    = [-9, 0]
  DEFAULT_HEIGHT_GAP_WOMEN  = [0, +9]

  FIND_N_ELIGIBLE_MATCHES = 5

  NEW_MATCHES_AT_HOUR = 12
  NEW_MATCHES_AT_MIN = 0

  MATCHING_MODELS = {
    preferences: {},
    location: { within_radius: Constants::NEAR_DISTANCE_METERS, ordered_by_proximity: true }
  }

  USE_MATCHING_MODELS = Rails.application.config.test_mode ? %w(location) : %w(preferences location desirability)

  module_function

  def introduction_suggestions_for(profile, skip_uuids=[])
    # who should I skip in finding new introductions?
    skip_uuids = [] if skip_uuids.nil?
    passed_uuids = skip_uuids + SkippedProfile.where(by: profile).pluck(:skipped_profile_uuid)

    # new requests first
    interested_profiles = Profile.where.not(uuid: passed_uuids).where(uuid: profile.got_intro_requests.pluck(:by_profile_uuid))

    # basic filters
    #   - approved members only (visible)
    #   - exclude myself, staff, those i've passed on, those i've already asked for an intro to, and mutually interested
    #   - desirability score >= HIGH_DESIRABILITY (7)
    profiles = Profile
                  .active
                  .visible
                  .not_staff
                  .where.not(uuid: profile.uuid)
                  .desirability_score_gte(Profile::HIGH_DESIRABILITY)
                  .within_distance(profile.latitude, profile.longitude, Constants::NEAR_DISTANCE_METERS)
                  .where.not(uuid: passed_uuids)
                  .where.not(uuid: interested_profiles.map(&:uuid))
                  .where.not(uuid: profile.asked_for_intros.pluck(:to_profile_uuid)) # don't show people i've already asked an intro to
                  .where.not(uuid: profile.got_intro_requests.where("CAST(properties->>'mutual' AS boolean) = true").pluck(:by_profile_uuid)) # don't show people who's intro request i've accepted

    # only introduce women to men
    profiles = profiles.of_gender(profile.seeking_gender) if profile.male?

    # age filter
    if profile.male?
      profiles = profiles
                    .age_gte(profile.age - 4)
                    .age_lte(profile.age + 2)
    else
      profiles = profiles
                  .age_gte(profile.age - 2)
                  .age_lte(profile.age + 4)
    end

    show_more = [0, (5-interested_profiles.count)].max

    # order by most recently active
    interested_profiles + profiles.ordered_by_last_seen.limit(show_more)
  end

  def create_first_matches(profile_uuid)
    profile = Profile.find(profile_uuid)
    existing_matches_sql = profile.matches.to_sql
    matchmaking_query = Profile.visible.not_staff.active.of_gender(profile.seeking_gender)
    matchmaking_query = matchmaking_query
                          .older_than(profile.seeking_minimum_age)
                          .younger_than(profile.seeking_maximum_age)
    matchmaking_query = matchmaking_query.within_distance(profile.search_lat, profile.search_lng, MATCHING_MODELS[:location][:within_radius])
    matchmaking_query = matchmaking_query.ordered_by_distance(profile.search_lat, profile.search_lng)
    matchmaking_query = matchmaking_query.desirability_score_gte(8).desirability_score_lte(10)

    matched_profiles =
      matchmaking_query
      .where.not(uuid: profile.uuid)
      .joins("LEFT OUTER JOIN (#{existing_matches_sql}) matches ON matches.matched_profile_uuid = profiles.uuid")
      .where(matches: { matched_profile_uuid: nil })
      .limit(FIND_N_ELIGIBLE_MATCHES)

    matched_profiles.each_with_index do |matched_profile, idx|
      EKC.logger.debug "creating match from #{profile.uuid} to #{matched_profile.uuid}"
      create_match_from_to(profile_uuid, matched_profile.uuid,
                            normalized_distance: nil,
                            friends_with: false,
                            num_common_friends: 0)
    end
  end

  # finds and creates new match entries
  # returns: number of new matches created
  def generate_new_matches_for(profile_uuid, opts = {})
    profile = Profile.find(profile_uuid)

    matched_profile_uuids = Matchmaker.new_eligible_matches(profile).map(&:uuid)
    if matched_profile_uuids.present?
      # TBD: compute scores!
      matched_profiles = matched_profile_uuids.map { |uuid|
                            begin
                              Profile.find(uuid)
                            rescue ActiveRecord::RecordNotFound
                              EKC.logger.error "Profile not found when looking up eligible matches. uuid: #{uuid}"
                              nil
                            end
                          }.compact
      normalized_distances = matched_profiles
                .map { |p| Geocoder::Calculations.distance_between([p.latitude, p.longitude], [profile.latitude, profile.longitude]) }
                .map { |dist| EKC.normalize_distance_km(dist) }

      matched_profiles.each_with_index do |matched_profile, idx|
        if opts[:onesided]
          EKC.logger.debug "creating match from #{profile.uuid} to #{matched_profile.uuid}"
          create_match_from_to(profile_uuid, matched_profile.uuid,
                                  normalized_distance: normalized_distances[idx],
                                  friends_with: profile.facebook_authentication.friends_with?(matched_profile.facebook_authentication.try(:oauth_uid)),
                                  num_common_friends: profile.facebook_authentication.mutual_friends_count(matched_profile.facebook_authentication.try(:oauth_uid)))
        else
          EKC.logger.debug "creating matches between #{profile.uuid} and #{matched_profile.uuid}"
          create_matches_between(profile_uuid, matched_profile.uuid,
                                  normalized_distance: normalized_distances[idx],
                                  friends_with: profile.facebook_authentication.friends_with?(matched_profile.facebook_authentication.try(:oauth_uid)),
                                  num_common_friends: profile.facebook_authentication.mutual_friends_count(matched_profile.facebook_authentication.try(:oauth_uid)))
        end
      end

      EKC.logger.info "#{profile_uuid}: #{matched_profiles.count} new matches"
    end

    matched_profiles.count rescue 0
  rescue ActiveRecord::RecordNotFound
    EKC.logger.error "Profile not found when generating matches for it. uuid: #{profile_uuid}"
    0
  end

  def create_match_from_to(p1_uuid, p2_uuid, match_params = {})
    p1 = Profile.find(p1_uuid)
    p2 = Profile.find(p2_uuid)

    initiator_uuid = p1.male? ? p1.uuid : p2.uuid

    with_params = { initiates_profile_uuid: initiator_uuid }.merge(match_params)

    match = Match.create_with(with_params)
                 .find_or_create_by(for_profile_uuid: p1.uuid, matched_profile_uuid: p2.uuid)

    match
  end

  def create_matches_between(p1_uuid, p2_uuid, match_params = {})
    p1 = Profile.find(p1_uuid)
    p2 = Profile.find(p2_uuid)

    initiator_uuid = p1.male? ? p1.uuid : p2.uuid

    with_params = { initiates_profile_uuid: initiator_uuid }.merge(match_params)

    match_1 = Match.create_with(with_params)
                   .find_or_create_by(for_profile_uuid: p1.uuid, matched_profile_uuid: p2.uuid)

    match_2 = Match.create_with(with_params)
                   .find_or_create_by(for_profile_uuid: p2.uuid, matched_profile_uuid: p1.uuid)

    [match_1, match_2]
  end

  def transition_to_mutual_match(profile_uuid, match_id)
    profile = Profile.find(profile_uuid)
    match = Match.find(match_id)

    profile.got_mutual_like!(:mutual_match, Rails.application.routes.url_helpers.v1_profile_match_path(profile.uuid, match.id))
    match.update(active: true, expires_at: (DateTime.now + Match::STALE_EXPIRATION_DURATION))
    match.reverse.update(active: true)

    PushNotifier.delay.record_event(profile.uuid, 'new_mutual_match', name: match.matched_profile.firstname)
    Match.delay_for(Match::STALE_EXPIRATION_DURATION).check_match_expiration(match.id, profile_uuid)
  rescue ActiveRecord::RecordNotFound
    EKC.logger.error "ERROR: #{self.name.to_s}##{__method__.to_s}: Profile #{profile_uuid} or match #{match_id} appears to have been deleted!"
  end

  def create_conversation(between_uuids=[])
    Conversation.find_or_create_by_participants!(between_uuids)
  end

  def new_eligible_matches(profile, opts = {})
    existing_matches_sql = profile.matches.to_sql

    matchmaking_query = Profile.visible.not_staff.active.of_gender(profile.seeking_gender)

    if USE_MATCHING_MODELS.include? 'preferences'
      matchmaking_query =
        matchmaking_query
        .older_than(profile.seeking_minimum_age)
        .younger_than(profile.seeking_maximum_age)
        .taller_than(profile.seeking_minimum_height_in)
        .shorter_than(profile.seeking_maximum_height_in)
        .of_faiths(profile.seeking_faith)
        .seeking_older_than(profile.age)
        .seeking_younger_than(profile.age)
        .seeking_taller_than(profile.height_in)
        .seeking_shorter_than(profile.height_in)
        .seeking_of_faith(profile.faith)
    end

    if USE_MATCHING_MODELS.include? 'location'
      if !Rails.application.config.test_mode
        matchmaking_query = matchmaking_query.within_distance(profile.search_lat, profile.search_lng, MATCHING_MODELS[:location][:within_radius])
      end
      if MATCHING_MODELS[:location][:ordered_by_proximity]
        matchmaking_query = matchmaking_query.ordered_by_distance(profile.search_lat, profile.search_lng)
      end
    end

    if USE_MATCHING_MODELS.include? 'desirability'
      matchmaking_query = matchmaking_query
                          .desirability_score_gte(match_desirability_score_min(profile))
                          .desirability_score_lte(match_desirability_score_max(profile))
    end

    matchmaking_query =
      matchmaking_query
      .where.not(uuid: profile.uuid)
      .joins("LEFT OUTER JOIN (#{existing_matches_sql}) matches ON matches.matched_profile_uuid = profiles.uuid")
      .where(matches: { matched_profile_uuid: nil })
      .limit(opts[:limit] || FIND_N_ELIGIBLE_MATCHES)
  end

  def match_desirability_score_min(profile)
    dscore = profile.desirability_score
    if dscore.blank?
      # if score not available, show top of stack
      return 7
    else
      if dscore >= 7
        # if score is among highest, show 1 below
        return (dscore.floor - 1)
      else
        # else show my score and above
        return dscore.floor
      end
    end

    7
  end

  def match_desirability_score_max(profile)
    10
  end

  # DEFAULT MATCH PREFERENCES

  def default_min_age_pref(gender, age)
    age_gap_lower = gender == Profile::GENDER_MALE ? Matchmaker::DEFAULT_AGE_GAP_MEN.first : Matchmaker::DEFAULT_AGE_GAP_WOMEN.first

    [age + age_gap_lower, Constants::MIN_AGE].max
  end

  def default_max_age_pref(gender, age)
    age_gap_upper = gender == Profile::GENDER_MALE ? Matchmaker::DEFAULT_AGE_GAP_MEN.second : Matchmaker::DEFAULT_AGE_GAP_WOMEN.second

    age + age_gap_upper
  end

  def default_min_ht_pref(gender, height)
    height_gap_lower = gender == Profile::GENDER_MALE ? Matchmaker::DEFAULT_HEIGHT_GAP_MEN.first : Matchmaker::DEFAULT_HEIGHT_GAP_WOMEN.first

    Constants::HEIGHT_RANGE[[(Constants::HEIGHT_RANGE.index(height) + height_gap_lower), 0].max]
  end

  def default_max_ht_pref(gender, height)
    height_gap_upper = gender == Profile::GENDER_MALE ? Matchmaker::DEFAULT_HEIGHT_GAP_MEN.second : Matchmaker::DEFAULT_HEIGHT_GAP_WOMEN.second

    Constants::HEIGHT_RANGE[[(Constants::HEIGHT_RANGE.index(height) + height_gap_upper), Constants::HEIGHT_RANGE.size-1].min]
  end

  def default_faith_pref
    Constants::FAITHS
  end
end
