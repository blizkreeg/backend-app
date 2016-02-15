class Api::V1::MatchesController < ApplicationController
  before_action :authenticated?
  before_action :validate_json_schema, except: []
  before_action except: [] do
    authorized?(params[:profile_uuid])
  end

  def index
    profile = Profile.find(params[:profile_uuid])

    # TBD implement matching logic
    opposite_gender = profile.male? ? 'female' : 'male'
    matched_profiles = Profile.with_gender(opposite_gender).limit(3).reorder("RANDOM()")

    if profile.matches.undecided.count > 0
      @matches = profile.matches.undecided
    else
      @matches = matched_profiles.map { |matched_profile|
                  male_uuid = profile.male? ? profile.uuid : matched_profile.uuid;
                  Match.create_with(delivered_at: DateTime.now,
                                    expires_at: DateTime.now + Match::STALE_EXPIRATION_DURATION,
                                    initiates_profile_uuid: male_uuid)
                  .find_or_create_by(for_profile_uuid: profile.uuid, matched_profile_uuid: matched_profile.uuid) }

      # TBD: creating a default conversation here. Update to do this on mutual match only!!
      @matches.each do |match|
        Conversation.new(participant_uuids: [profile.uuid, match.matched_profile_uuid]).save!
      end

      profile.new_matches!(:has_matches, v1_profile_matches_path(profile))
      profile.deliver_matches!(:show_matches, v1_profile_matches_path(profile))
    end

    # @matches = profile.matches.includes(:matched_profile).undecided.take(Constants::N_MATCHES_AT_A_TIME)

    @matches.map { |match| Match.delay.update_delivery_time(match.id) }
    render status: 200
  end

  def show
    @match = Match.includes(:matched_profile).find(params[:id])

    @match.test_and_set_expiration! if @current_profile.mutual_match?
    Match.delay.update_delivery_time(@match.id)

    render status: 200
  end

  def update
    profile = Profile.find(params[:profile_uuid])
    match_ids = params[:data].map { |match| match[:id] }
    match_properties = params[:data].map { |match| match_params(match) }
    Match.update(match_ids, match_properties)

    # TBD: here account for user who is waiting for response!
    profile.decided_on_matches!(:waiting_for_matches) if profile.matches.undecided.count == 0

    Match.delay.mark_if_mutual_like(match_ids)

    render status: 200
  end

  def destroy
    match = Match.find(params[:id])
    match.unmatch!(params[:data][:reason])

    @current_profile.unmatch!(:waiting_for_matches)
    # TBD: after X hours, wake up the other person to see if they want to unmatch

    render status: 200
  end

  private

  def match_params(parameters)
    attributes = Match::MASS_UPDATE_ATTRIBUTES
    Match::ATTRIBUTES.each do |attr_name, type|
      attributes.delete(attr_name.to_sym) if type == :array
      attributes += [{ attr_name.to_sym => [] }]
    end
    parameters.permit(*attributes)
  end
end
