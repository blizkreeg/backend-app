json.data do
  json.partial! 'api/v1/conversations/conversation', conversation: @conversation
end
json.partial! 'api/v1/shared/auth'
