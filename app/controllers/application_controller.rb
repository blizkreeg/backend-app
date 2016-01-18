class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :authenticate_token!
  before_action :set_current_user

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: { message: e.message }, status: :not_found
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: { message: e.message }, status: :bad_request
  end

  rescue_from Errors::AuthTokenTimeoutError do
    render json: { message: 'Authentication token has expired' }, status: :unauthorized
  end

  protected

  def authenticate_user!
    if @current_user.blank?
      render json: { message: 'User not authorized' }, status: :unauthorized
    end
  end

  private

  def authenticate_token!
    raise Errors::AuthTokenTimeoutError, "invalid auth token" if decoded_auth_token.present? && auth_token_expired?
  end

  def set_current_user
    if auth_token_data.present? && auth_token_data.try(:[], 'user_id').present?
      @current_user = User.find(auth_token_data['user_id'])
    end
  rescue ActiveRecord::RecordNotFound
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
