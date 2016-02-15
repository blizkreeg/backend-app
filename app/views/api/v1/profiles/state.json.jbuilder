json.data do
  json.partial! 'api/v1/profiles/state', profile: @profile
end
json.partial! 'api/v1/shared/auth'
