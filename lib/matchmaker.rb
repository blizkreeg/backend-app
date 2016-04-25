module Matchmaker

  DEFAULT_AGE_GAP_MEN   = [-5, 0]
  DEFAULT_AGE_GAP_WOMEN = [0, +5]

  DEFAULT_HEIGHT_GAP_MEN    = [-7, 0]
  DEFAULT_HEIGHT_GAP_WOMEN  = [0, +7]

  N_MATCHES_AT_A_TIME = 5

  MATCHING_MODELS = {
    preferences: {},
    location: { within_radius: Constants::NEAR_DISTANCE_METERS, ordered_by_proximity: true }
  }

  APPLY_MATCHING_MODELS = Rails.application.config.test_mode ? %w(location) : %w(preferences location)

  module_function

  def generate_new_matches_for(profile_uuid)
    profile = Profile.find(profile_uuid)

    return if profile.matches.undecided.count > 0 || profile.show_matches?

    matched_profile_uuids = Matchmaker.new_eligible_matches(profile).map(&:uuid)
    if matched_profile_uuids.present?
      # TBD: compute scores!
      begin
        matched_profiles = Profile.find(matched_profile_uuids)
      rescue ActiveRecord::RecordNotFound
        EKC.logger.error "ERROR: #{self.class.name.to_s}##{__method__.to_s}: One or more profiles appear to have been deleted! #{matched_profile_uuids.inspect}"
        return
      end
      # TBD: temporarily scores are distance between the matched users
      scores =  matched_profiles.map { |p| Geocoder::Calculations.distance_between([p.latitude, p.longitude], [profile.latitude, profile.longitude]) }
      profile.add_matches_to_queue(matched_profile_uuids, scores)
      profile.update!(has_new_queued_matches: true)
    end
  rescue ActiveRecord::RecordNotFound
    EKC.logger.error "ERROR: #{self.class.name.to_s}##{__method__.to_s}: Profile appears to have been deleted: #{profile_uuid}!"
  end

  def create_matches_between(profile_uuid, matched_profile_uuids)
    profile = Profile.find(profile_uuid)

    if matched_profile_uuids.present?
      # create records in the matches table
      matched_profile_uuids.each do |matched_profile_uuid|
        create_one_way_match(profile.uuid, matched_profile_uuid)
      end

      # change the user state
      case profile.state
      when 'waiting_for_matches'
        profile.new_matches!(:has_matches)
      when 'waiting_for_matches_and_response'
        profile.new_matches!(:has_matches_and_waiting_for_response)
      end

      PushNotifier.delay.notify_one(profile.uuid, 'new_matches')
    end
  rescue ActiveRecord::RecordNotFound
    EKC.logger.error "ERROR: #{self.class.name.to_s}##{__method__.to_s}: Profile #{profile_uuid} appears to have been deleted!"
  end

  def create_two_way_match_between(p1_uuid, p2_uuid)
    profile_one = Profile.find p1_uuid
    profile_two = Profile.find p2_uuid

    initiator_uuid = profile_one.male? ? profile_one.uuid : profile_two.uuid

    # TBD: check if delivered_at and expires_at are needed
    # Match.create_with(delivered_at: DateTime.now,
    #                                    expires_at: DateTime.now + Match::STALE_EXPIRATION_DURATION,
    #                                    initiates_profile_uuid: male_uuid)
    match_1 = Match.create_with(initiates_profile_uuid: initiator_uuid)
                      .find_or_create_by(for_profile_uuid: profile_one.uuid, matched_profile_uuid: profile_two.uuid)
    # TBD: THIS NEEDS FIXING. we should create this side of the match too so
    # that both people see each other in a reasonable time.
    # however, how do we notify the other when the time is right for them?
    match_2 = Match.create_with(initiates_profile_uuid: initiator_uuid)
                      .find_or_create_by(for_profile_uuid: profile_two.uuid, matched_profile_uuid: profile_one.uuid)

    [match_1, match_2]
  end

  def create_one_way_match(p1_uuid, p2_uuid)
    profile_one = Profile.find p1_uuid
    profile_two = Profile.find p2_uuid

    initiator_uuid = profile_one.male? ? profile_one.uuid : profile_two.uuid

    # TBD: check if delivered_at and expires_at are needed
    # Match.create_with(delivered_at: DateTime.now,
    #                                    expires_at: DateTime.now + Match::STALE_EXPIRATION_DURATION,
    #                                    initiates_profile_uuid: male_uuid)
    match_1 = Match.create_with(initiates_profile_uuid: initiator_uuid)
                      .find_or_create_by(for_profile_uuid: profile_one.uuid, matched_profile_uuid: profile_two.uuid)
    # TBD: THIS NEEDS FIXING. we should create this side of the match too so
    # that both people see each other in a reasonable time.
    # however, how do we notify the other when the time is right for them?
    # match_2 = Match.create_with(initiates_profile_uuid: initiator_uuid)
    #                   .find_or_create_by(for_profile_uuid: profile_two.uuid, matched_profile_uuid: profile_one.uuid)

    [match_1, nil]
  end

  # def determine_mutual_matches(profile_uuid)
  #   profile = Profile.find(profile_uuid)

  #   # TBD: don't update the girl's state yet!
  #   mutual_match = profile.matches.mutual.detect { |match| match.matched_profile.waiting_for_matches? }
  #   profile.got_mutual_like!(:mutual_match, Rails.application.routes.url_helpers.v1_profile_match_path(profile.uuid, mutual_match.id))
  #   mutual_match.matched_profile.got_mutual_like!(:mutual_match, Rails.application.routes.url_helpers.v1_profile_match_path(mutual_match.matched_profile.uuid, mutual_match.reverse.id))

  #   # TBD: don't send the girl's notification here!
  #   PushNotifier.delay.notify_one(profile.uuid, 'new_mutual_match', name: mutual_match.matched_profile.firstname)
  #   PushNotifier.delay.notify_one(mutual_match.matched_profile.uuid, 'new_mutual_match', name: profile.firstname)
  # end

  def transition_to_mutual_match(profile_uuid, match_id)
    profile = Profile.find(profile_uuid)
    match = Match.find(match_id)

    profile.got_mutual_like!(:mutual_match, Rails.application.routes.url_helpers.v1_profile_match_path(profile.uuid, match.id))
    match.update(active: true, expires_at: (DateTime.now + Match::STALE_EXPIRATION_DURATION))
    match.reverse.update(active: true)

    PushNotifier.delay.notify_one(profile.uuid, 'new_mutual_match', name: match.matched_profile.firstname)
  rescue ActiveRecord::RecordNotFound
    EKC.logger.error "ERROR: #{self.class.name.to_s}##{__method__.to_s}: Profile #{profile_uuid} or match #{match_id} appears to have been deleted!"
  end

  def create_conversation(between_uuids=[])
    Conversation.find_or_create_by_participants!(between_uuids)
  end

  def new_eligible_matches(profile, opts = {})
    existing_matches_sql = profile.matches.to_sql

    matchmaking_query = Profile.active.of_gender(profile.seeking_gender)

    if APPLY_MATCHING_MODELS.include? 'preferences'
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

    if APPLY_MATCHING_MODELS.include? 'location'
      unless Rails.application.config.test_mode
        matchmaking_query = matchmaking_query.within_distance(profile.search_lat, profile.search_lng, MATCHING_MODELS[:location][:within_radius])
      end
      if MATCHING_MODELS[:location][:ordered_by_proximity]
        matchmaking_query = matchmaking_query.ordered_by_distance(profile.search_lat, profile.search_lng)
      end
    end

    matchmaking_query =
      matchmaking_query
      .where.not(uuid: profile.uuid)
      .joins("LEFT OUTER JOIN (#{existing_matches_sql}) matches ON matches.matched_profile_uuid = profiles.uuid")
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
