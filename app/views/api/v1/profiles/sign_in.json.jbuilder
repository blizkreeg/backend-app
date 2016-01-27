json.data do
  json.partial! 'api/v1/profiles/profile', profile: @profile
end
json.partial! 'api/v1/shared/auth'
