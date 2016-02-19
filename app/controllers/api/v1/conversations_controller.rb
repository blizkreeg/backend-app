class Api::V1::ConversationsController < ApplicationController
  before_action :authenticated?
  before_action :validate_json_schema, except: []
  before_action except: [] do
    authorized?(params[:profile_uuid])
  end
  before_action :load_conversation, only: [:update, :show]

  def update
    # beginning of the conversation?
    new_conversation = @conversation.fresh?

    # now append the message
    @conversation.append_message!(params[:data][:content], @current_profile.uuid)

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
      # open for chat
      @conversation.open! unless @conversation.open
    end

    @current_profile.reload

    render status: 200
  end

  def show
    render status: 200
  end

  private

  def load_conversation
    @conversation = Conversation.find(params[:id])
  end
end
