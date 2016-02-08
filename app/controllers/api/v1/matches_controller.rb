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
    @matches = matched_profiles.map { |matched_profile|
                  Match.create_with(delivered_at: DateTime.now)
                  .find_or_create_by(for_profile_uuid: profile.uuid, matched_profile_uuid: matched_profile.uuid) }

    if @matches.present?
      profile.new_matches!(:has_matches, v1_profile_matches_path(profile))
      profile.deliver_matches!(:show_matches, v1_profile_matches_path(profile))
    end
    # @matches = profile.matches.includes(:matched_profile).undecided.take(Constants::N_MATCHES_AT_A_TIME)

    @matches.map { |match| Match.delay.update_delivery_time(match.id) }
    render status: 200
  end

  def show
    @match = Match.includes(:matched_profile).find(params[:id])

    render status: 200
  end

  def update
    profile = Profile.find(params[:profile_uuid])
    match_ids = params[:data].map { |m| m[:id] }
    match_decisions = params[:data].map { |m| { decision: m[:decision] } }
    Match.update(match_ids, match_decisions)

    profile.decided_on_matches!(:waiting_for_matches) if profile.matches.undecided.count == 0

    render status: 200, json: {}
  end
end
