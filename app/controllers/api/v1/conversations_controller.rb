class Api::V1::ConversationsController < ApplicationController
  before_action :authenticated?
  before_action :validate_json_schema, except: []
  before_action except: [] do
    authorized?(params[:profile_uuid])
  end

  def update
    @conversation = Conversation.find(params[:id])
    recipient_uuid = (@conversation.participant_uuids - [@current_profile.uuid]).first
    message = Message.new(content: params[:data][:content], sender_uuid: @current_profile.uuid, recipient_uuid: recipient_uuid)
    @conversation.messages.push(message)
    @conversation.save!

    render status: 200
  rescue ActiveRecord::RecordNotFound
    respond_with_error('Conversation not found', 404)
  end
end
