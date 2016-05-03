class ApplicationController < ActionController::Base
  include JsonSchemaValidator

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  before_action :authenticate_token!
  before_action :set_current_profile
  # before_action :prepare_exception_notifier

  after_action :log_response

  UNAUTHORIZED_BAD_TOKEN = 'invalid_token'
  UNAUTHORIZED_EXPIRED_TOKEN = 'token_expired'
  UNAUTHORIZED_PROFILE_NOT_FOUND = 'profile_not_found'

  rescue_from StandardError, with: :server_error
  rescue_from ActiveRecord::UnknownAttributeError, with: lambda { |e| notify_of_exception(e); respond_with_error(e.message, 400) } # :bad_request
  rescue_from ActiveRecord::RecordNotFound, with: lambda { |e| respond_with_error(e.message, 404) } # :not_found
  rescue_from Errors::OperationNotPermitted, with: lambda { |e| notify_of_exception(e); respond_with_error(e.message, 403) } # :forbidden
  rescue_from Errors::AuthTokenTimeoutError, with: lambda { |e| notify_of_exception(e); respond_with_error(e.message, 401, UNAUTHORIZED_EXPIRED_TOKEN) } # :unauthorized
  rescue_from ActionController::ParameterMissing, with: lambda { |e| notify_of_exception(e); respond_with_error(e.message, 400) } # :bad_request
  rescue_from Errors::FacebookAuthenticationError, with: lambda { |e| notify_of_exception(e); reset_current_profile!; respond_with_error(e.message, 401, 'facebook_session_invalid') }
  rescue_from Errors::FacebookPermissionsError, with: lambda { |e| notify_of_exception(e); reset_current_profile!; respond_with_error(e.message, 401, 'insufficient_facebook_permissions') }
  rescue_from JSON::Schema::ValidationError, with: lambda { |e| notify_of_exception(e); respond_with_error(e.message, 400) } # :bad_request

  def route_not_found
    render file: 'public/404.html', layout: false, status: :not_found
  end

  protected

  def authenticated?
    if @current_profile.blank?
      if @profile_not_found
        respond_with_error('Access Restricted', 401, UNAUTHORIZED_PROFILE_NOT_FOUND)
      else
        respond_with_error('Access Restricted', 401, UNAUTHORIZED_BAD_TOKEN)
      end
    end
  end

  def authorized?(uuid)
    raise ActionController::ParameterMissing, "Request not valid" if uuid.blank?
    authenticated?
    raise Errors::OperationNotPermitted, "Operation not permitted" if uuid != @current_profile.try(:uuid)
  end

  def auth_response_hash
    @current_profile.present? ?
      { auth: { token: JsonWebToken.encode(@current_profile.auth_token_payload), expires_at: Constants::TOKEN_EXPIRATION_TIME_STR } } :
      { auth: nil }
  end

  def notify_of_exception(exception)
    ExceptionNotifier.notify_exception(exception, env: request.env)
  end

  def respond_with_error(message, http_status_code, internal_error_code=nil)
    response = { error: { message: message, http_status: http_status_code, code: internal_error_code } }
    response.merge!(auth_response_hash)
    render json: response, status: http_status_code
  end

  private

  def prepare_exception_notifier
    request.env["exception_notifier.exception_data"] = {
      :request_path => request.fullpath
    }

    request.env["exception_notifier.exception_data"].merge!({
      :profile_uuid => @current_profile.uuid,
    }) if @current_profile.present?
  end

  def log_response
    if response.content_type == 'application/json'
      EKC.logger.debug "REQUEST  (#{@current_profile.try(:uuid) || 'noauth'}): #{request.fullpath}"
      EKC.logger.debug "RESPONSE (#{@current_profile.try(:uuid) || 'noauth'}): #{response.body}"
    end
  end

  def authenticate_token!
    raise Errors::AuthTokenTimeoutError, "Authentication token has expired" if decoded_auth_token.present? && auth_token_expired?
  end

  def set_current_profile(profile=nil)
    @profile_not_found = false
    if profile.present?
      @current_profile = profile
      @current_profile.update!(signed_in_at: DateTime.now.utc)
    elsif auth_token_data.present? && auth_token_data.try(:[], 'profile_uuid').present?
      @current_profile = Profile.find(auth_token_data['profile_uuid'])
      EKC.logger.debug "Request from #{@current_profile.uuid}, path: #{request.path}"
    end
  rescue ActiveRecord::RecordNotFound
    @current_profile = nil
    @profile_not_found = true
  end

  def reset_current_profile!
    @current_profile = nil
  end

  def auth_token_expired?
    auth_token_data && (auth_token_data['exp'] < Time.now.to_i)
  end

  def decoded_auth_token
    @decoded_auth_token ||= JsonWebToken.decode(http_auth_header_content)
  end

  def auth_token_data
    @decoded_auth_token.try(:first)
  end

  def http_auth_header_content
    return @http_auth_header_content if defined? @http_auth_header_content

    @http_auth_header_content = begin
      if request.headers['Authorization'].present?
        request.headers['Authorization'].split(' ').last
      else
        nil
      end
    end
  end

  def server_error(e)
    notify_of_exception(e)
    Rails.logger.error("#{e.class.name}:#{e.message}\n#{e.backtrace.join('\n')}")
    respond_with_error(e.message, 500)
  end
end
