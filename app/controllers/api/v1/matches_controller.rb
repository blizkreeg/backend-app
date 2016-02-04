class Api::V1::MatchesController < ApplicationController
  before_action :authenticated?
  before_action :validate_json_schema, except: []
  before_action except: [] do
    authorized?(params[:profile_uuid])
  end

  def index
    user_profile = Profile.find(params[:profile_uuid])

    # TBD implement matching logic
    opposite_gender = user_profile.male? ? 'female' : 'male'
    profiles = Profile.with_gender(opposite_gender).limit(3).reorder("RANDOM()")
    @matches = profiles.map { |profile|
                  Match.create_with(delivered_at: DateTime.now).find_or_create_by(for_profile_uuid: user_profile.uuid, matched_profile_uuid: profile.uuid)
               }
    # @matches = profile.matches.includes(:matched_profile).undecided.take(Constants::N_MATCHES_AT_A_TIME)

    render status: 200
  end

  def show
  end

  def update
    render status: 200, json: {}
  end
end
