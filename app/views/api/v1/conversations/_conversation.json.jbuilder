json.(conversation, :id, :uuid, :closes_at, :state)
json.messages do
  json._meta do
    json.null!
  end
  json.items do
    json.array! conversation.messages.limit(Message::LIMIT_N_MESSAGES) do |message|
      json.partial! 'api/v1/messages/message', message: message
    end
  end
end
json.ready_to_meet do
  json.set! conversation.initiator.uuid.to_s, conversation.meeting_readinesses.by_profile(conversation.initiator.uuid).take.try(:value)
  json.set! conversation.responder.uuid.to_s, conversation.meeting_readinesses.by_profile(conversation.responder.uuid).take.try(:value)
end
