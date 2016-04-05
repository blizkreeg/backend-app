module Errors
  class AuthTokenTimeoutError < StandardError; end
  class OperationNotPermitted < StandardError; end
  class FacebookAuthenticationError < StandardError; end


  EMAIL_EXISTS_ERROR_STR = 'already exists'
end
