class Api::V1::ConversationsController < ApplicationController
  before_action :authenticated?
  before_action :validate_json_schema, except: []
  before_action except: [] do
    authorized?(params[:profile_uuid])
  end
  before_action :load_conversation, only: [:update, :show, :record_conversation_health, :record_ready_to_meet, :record_meeting_details, :show_date_suggestions]

  def update
    # beginning of the conversation?
    new_conversation = @conversation.fresh?

    # now append the message
    @conversation.add_message!(params[:data][:content], @current_profile.uuid)

    # message from the initiator?
    if @current_profile.initiated_conversation?(@conversation)
      # first message
      if new_conversation
        # find my match record
        my_match = Match.where(for_profile_uuid: @current_profile.uuid, matched_profile_uuid: @conversation.responder.uuid).take!

        # update state - started the conversation and now waiting for a response + getting matches
        @current_profile.started_conversation!(:waiting_for_matches_and_response, v1_profile_match_path(@current_profile.uuid, my_match.id))

        # update state of my mutual match so she/he sees the mutual like and the message
        @conversation.responder.got_first_message!(:mutual_match, v1_profile_match_path(@conversation.responder.uuid, my_match.reverse.id))

        # send push to the other
        PushNotifier.delay.record_event(@conversation.responder.uuid, 'new_mutual_match', name: @current_profile.firstname)

        # update the expiration for the responder
        my_match.reverse.update(expires_at: (DateTime.now + Match::STALE_EXPIRATION_DURATION))

        # after N time, check if responder has responded
        Match.delay_for(Match::STALE_EXPIRATION_DURATION).check_match_expiration(my_match.reverse.id, @conversation.responder.uuid)

        ProfileEventLogWorker.perform_async(@current_profile.uuid, :started_conversation, uuid: @conversation.responder.try(:uuid))
      end
    elsif @current_profile.responding_to_conversation?(@conversation)
      # open chat -> moves both users to 'in_conversation' state
      @conversation.open! unless @conversation.open
      ProfileEventLogWorker.perform_async(@current_profile.uuid, :responded_to_conversation, uuid: @conversation.initiator.try(:uuid))
    end

    render status: 200
  end

  def show
    render status: 200
  end

  def record_conversation_health
    health = ConversationHealth.find_or_create_by(profile_uuid: @current_profile.uuid, conversation_id: @conversation.id)
    health.update!(value: params[:data][:value])

    render 'api/v1/shared/nodata', status: 200
  end

  def record_ready_to_meet
    real_date = RealDate.find_or_create_by(profile_uuid: @current_profile.uuid, conversation_id: @conversation.id)
    real_date.update!(real_date_parameters)

    Conversation.delay_for(Conversation::SHOW_DATE_SUGGESTIONS_DELAY).move_conversation_to(@conversation.id, 'show_date_suggestions') if @conversation.both_ready_to_meet?

    render 'api/v1/shared/nodata', status: 200
  end

  # TBD : TEST AND DEBUG THIS + schedule job to switch user to post-date feedback
  # if scheduled job fires before conv close, reschedule it for 24.hours after conv. close, leave user substate unchanged
  # else update substate to post-date feedback
  def record_meeting_details
    real_date = RealDate.find_or_create_by(profile_uuid: @current_profile.uuid, conversation_id: @conversation.id)

    tz_offset = ActiveSupport::TimeZone.new(real_date.profile.time_zone).utc_offset / 3600 rescue 0
    params[:data][:meeting_at] = Time.at((params[:data][:meeting_at]/1000).to_i)

    real_date.update!(real_date_parameters)

    render 'api/v1/shared/nodata', status: 200
  end

  def show_date_suggestions
    if @conversation.date_suggestions.blank?
      common = @conversation.initiator.date_preferences & @conversation.responder.date_preferences
      union = (@conversation.initiator.date_preferences + @conversation.responder.date_preferences).uniq
      preferred = common.present? ? common : union
      suggested = DatePlace.with_date_types(preferred).order("RANDOM()").limit(DateSuggestion::NUM_SUGGESTIONS)
      @conversation.date_suggestions = suggested.map { |place|
        type_of_date = place.date_types[rand(place.date_types.size)]
        day_of_week = DateSuggestion.weekend_days(DateTime.now.in_time_zone(@current_profile.time_zone)).sample
        DateSuggestion.new(day_of_week: day_of_week, type_of_date: type_of_date, date_place_id: place.id)
      }
    end

    render status: 200
  end

  private

  def load_conversation
    @conversation = Conversation.find(params[:id] || params[:conversation_id])
  end

  def real_date_parameters
    attributes = RealDate::MASS_UPDATE_ATTRIBUTES
    params.require(:data).permit(*attributes)
  end
end
