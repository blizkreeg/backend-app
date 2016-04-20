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
      end
    elsif @current_profile.responding_to_conversation?(@conversation)
      # open chat -> moves both users to 'in_conversation' state
      @conversation.open! unless @conversation.open
    end

    @current_profile.reload

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

  def record_meeting_details
    real_date = RealDate.find_or_create_by(profile_uuid: @current_profile.uuid, conversation_id: @conversation.id)

    tz_offset = ActiveSupport::TimeZone.new(real_date.profile.time_zone).utc_offset / 3600 rescue 0
    params[:data][:meeting_at] = Time.at((params[:data][:meeting_at]/1000).to_i)

    real_date.update!(real_date_parameters)

    render 'api/v1/shared/nodata', status: 200
  end

  # TBD: needs a proper algorithm!
  def show_date_suggestions
    if @conversation.date_suggestions.blank?

      # TBD: prioritize common first, then others
      preferred_dates = @conversation.participants.map(&:date_preferences).flatten.compact.first(DateSuggestion::NUM_SUGGESTIONS)
      # TBD: restrict by preferred types
      places = DatePlace.limit(DateSuggestion::NUM_SUGGESTIONS).order("RANDOM()")

      @conversation.date_suggestions = places.map { |place|
        type_of_date = place.date_types[rand(place.date_types.size)]
        # TBD: day of week here can be wrong if it's Friday. We could end up getting a date in the past.
        # This should be smarter!
        DateSuggestion.new(day_of_week: (Date.today.end_of_week - rand(3)), type_of_date: type_of_date, date_place_id: place.id)
      }

      @conversation.save!
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
