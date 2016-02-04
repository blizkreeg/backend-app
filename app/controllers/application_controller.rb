class ApplicationController < ActionController::Base
  include JsonSchemaValidator

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  before_action :authenticate_token!
  before_action :set_current_profile

  rescue_from StandardError, with: lambda { |e| Rails.logger.error("#{e.class.name}:#{e.message}\n#{e.backtrace.join('\n')}"); respond_with_error(e.message, 500) } # :internal_server_error
  rescue_from ActiveRecord::RecordNotFound, with: lambda { |e| respond_with_error(e.message, 404) } # :not_found
  rescue_from Errors::OperationNotPermitted, with: lambda { |e| respond_with_error(e.message, 403) } # :forbidden
  rescue_from Errors::AuthTokenTimeoutError, with: lambda { |e| respond_with_error(e.message, 401, 'token_expired') } # :unauthorized
  rescue_from ActionController::ParameterMissing, with: lambda { |e| respond_with_error(e.message, 400) } # :bad_request
  rescue_from JSON::Schema::ValidationError, with: lambda { |e| respond_with_error(e.message, 400) } # :bad_request

  protected

  def authenticated?
    respond_with_error('Access Restricted', 401, 'invalid_token') if @current_profile.blank? # :unauthorized
  end

  def authorized?(uuid)
    raise ActionController::ParameterMissing, "Request not valid" if uuid.blank?
    authenticated?
    raise Errors::OperationNotPermitted, "Operation not permitted" if uuid != @current_profile.try(:uuid)
  end

  def auth_response_hash
    @current_profile.present? ?
      { auth: { token: JsonWebToken.encode(@current_profile.auth_token_payload), expires_at: Constants::TOKEN_EXPIRATION_TIME_STR } } :
      { auth: {} }
  end

  def respond_with_error(message, http_status_code, internal_error_code=nil)
    response = { error: { message: message, http_status: http_status_code, code: internal_error_code } }
    response.merge!(auth_response_hash)
    render json: response, status: http_status_code
  end

  private

  def authenticate_token!
    raise Errors::AuthTokenTimeoutError, "Authentication token has expired" if decoded_auth_token.present? && auth_token_expired?
  end

  def set_current_profile(profile=nil)
    if profile.present?
      @current_profile = profile
    elsif auth_token_data.present? && auth_token_data.try(:[], 'profile_uuid').present?
      @current_profile = Profile.find(auth_token_data['profile_uuid'])
      EKC.logger.debug "Request from #{@current_profile.uuid}, path: #{request.path}"
    end
  rescue ActiveRecord::RecordNotFound
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
end
