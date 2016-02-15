class Api::V1::ConversationsController < ApplicationController
  before_action :authenticated?
  before_action :validate_json_schema, except: []
  before_action except: [] do
    authorized?(params[:profile_uuid])
  end

  def update
    @conversation = Conversation.find(params[:id])

    new_conversation = @conversation.fresh?

    # append message to conversation
    content = params[:data][:content]
    if content.present?
      message = Message.new(content: content,
                            sender_uuid: @current_profile.uuid,
                            recipient_uuid: @conversation.the_other_who_is_not(@current_profile.uuid).uuid)
      @conversation.messages.push(message)
      @conversation.save!
    end

    # was this conversation just initiated?
    if @current_profile.initiated_conversation?(@conversation) && new_conversation
      # TBD: Fill in URL!
      # update state - started the conversation and now waiting for a response (but continues to get matches)
      @current_profile.started_conversation!(:waiting_for_matches_and_response, 'URLLLLL')

      # update state of the other who will now see the mutual like and the message
      recipient = @conversation.responder
      match = Match.where(for_profile_uuid: recipient.uuid, matched_profile_uuid: @current_profile.uuid).take!
      recipient.got_first_message!(:mutual_match, v1_profile_match_path(recipient.uuid, match.id))
    elsif @current_profile.responding_to_conversation?(@conversation)
      # if responding to the conversation starter, open the conv. for chat
      @conversation.open!
    end

    render status: 200
  rescue ActiveRecord::RecordNotFound
    respond_with_error('Conversation not found', 404)
  end
end
