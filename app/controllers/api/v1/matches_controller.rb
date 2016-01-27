class Api::V1::MatchesController < ApplicationController
  before_action :restrict_to_authenticated_clients
  before_action :validate_json_schema, except: []

  def index
    # TBD: implement matching logic
    # @profiles = Profile.limit(3).reorder("RANDOM()")
    profile = Profile.find(params[:profile_uuid])
    @matches = profile.matches.includes(:matched_profile).undecided.take(Constants::N_MATCHES_AT_A_TIME)

    render status: 200
  end

  def show
  end

  def update
  end
end
