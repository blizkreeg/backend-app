json.data do
  json._meta nil
  json.items do
    json.array! @matches do |match|
      json.match_info do
        json.partial! 'api/v1/matches/match', match: match
      end
      json.matched_profile do
        json.partial! 'api/v1/profiles/profile', profile: match.matched_profile, match: match
      end
      json.match_conversation do
        if match.conversation.present?
          json.partial! 'api/v1/conversations/conversation', conversation: match.conversation
        else
          json.null!
        end
      end
    end
  end
end
json.partial! 'api/v1/shared/auth'
