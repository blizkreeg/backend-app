json.data do
  json._meta nil
  json.match_info do
    json.partial! 'api/v1/matches/match', match: @match
  end
  json.matched_profile do
    json.partial! 'api/v1/profiles/profile', profile: @match.matched_profile
  end
  json.match_conversation do
    json.partial! 'api/v1/conversations/conversation', conversation: @match.conversation
  end
end
json.partial! 'api/v1/shared/auth'
