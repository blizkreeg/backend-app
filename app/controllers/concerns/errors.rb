module Errors
  class AuthTokenTimeoutError < StandardError; end
  class OperationNotPermitted < StandardError; end
  class FacebookAuthenticationError < StandardError; end
  class FacebookPermissionsError < StandardError; end
  class InvalidPushNotificationPayload < StandardError; end

  EMAIL_EXISTS_ERROR_STR = 'already exists'
end
