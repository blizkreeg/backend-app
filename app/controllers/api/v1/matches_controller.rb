class Api::V1::MatchesController < ApplicationController
  before_action :authenticated?
  before_action :validate_json_schema, except: []
  before_action except: [] do
    authorized?(params[:profile_uuid])
  end

  def index
    profile = Profile.find(params[:profile_uuid])

    @matches = profile.matches.includes(:matched_profile).undecided.take(Constants::N_MATCHES_AT_A_TIME)

    # transition state if there are matches to show
    if @matches.count > 0
      case profile.state.to_sym
      when :waiting_for_matches
        profile.new_matches!(:has_matches, v1_profile_matches_path(profile))
        profile.deliver_matches!(:show_matches, v1_profile_matches_path(profile))
      when :has_matches
        profile.deliver_matches!(:show_matches, v1_profile_matches_path(profile))
      when :show_matches
        # do nothing
      when :waiting_for_matches_and_response
        waiting_on_match = profile.active_mutual_match
        profile.new_matches!(:has_matches_and_waiting_for_response, v1_profile_match_path(profile.uuid, waiting_on_match.id))
        profile.deliver_matches!(:show_matches_and_waiting_for_response, v1_profile_match_path(profile.uuid, waiting_on_match.id))
      when :has_matches_and_waiting_for_response
        waiting_on_match = profile.active_mutual_match
        profile.deliver_matches!(:show_matches_and_waiting_for_response, v1_profile_match_path(profile.uuid, waiting_on_match.id))
      when :show_matches_and_waiting_for_response
        # do nothing
      end

      @matches.map { |match| Match.delay.update_delivery_time(match.id) }
      ProfileEventLogWorker.perform_async(@current_profile.uuid, :was_delivered_matches, uuids: @matches.map(&:matched_profile).map(&:uuid))
    else
      ProfileEventLogWorker.perform_async(@current_profile.uuid, :checked_got_no_matches)
    end

    render status: 200
  end

  def show
    @match = Match.includes(:matched_profile).find(params[:id])
    ProfileEventLogWorker.perform_async(@current_profile.uuid, :viewed_match, uuid: @match.matched_profile.try(:uuid))
    render status: 200
  end

  def update
    profile = Profile.find(params[:profile_uuid])
    match_ids = params[:data].map { |match| match[:id] }
    match_properties = params[:data].map { |match| match_params(match) }
    Match.update(match_ids, match_properties)

    # TBD: here account for user who is waiting for response!
    # TBD: we are forcefully transitioning the user to the default state here
    # what if they have more matches that we should show?
    case profile.state.to_sym
    when :show_matches
      profile.decided_on_matches!(:waiting_for_matches)
    when :show_matches_and_waiting_for_response
      waiting_on_match = profile.active_mutual_match
      profile.decided_on_matches!(:waiting_for_matches_and_response, v1_profile_match_path(profile.uuid, waiting_on_match.id))
    end

    Match.delay.enable_mutual_flag_and_create_conversation!(match_ids)

    render status: 200
  end

  # Situations when Unmatch can happen:
  # 1. when in a mutual_match state
  # 2. when in open conversation
  # 3. user reports when in conversation
  def destroy
    match = Match.find(params[:id])
    match.unmatch!(params[:data][:reason])

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
