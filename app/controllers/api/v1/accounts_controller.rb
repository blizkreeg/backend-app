class Api::V1::AccountsController < ApplicationController
  def index
  end

  def sign_in
    auth_hash = JSON.parse(params[:facebook_auth_hash]).with_indifferent_access
    Rails.logger.info "Logged in with Facebook, auth hash =====> \n#{auth_hash.inspect}"

    uid = auth_hash[:uid]

    Rails.logger.info "UID #{uid}"

    render text: 'success!'
  rescue ActiveRecord::RecordNotFound
    error
    respond_to do |format|
      format.json {
        render json: { message: "Account with UID #{uid} not found" }, status: 404
      }
    end
  rescue StandardError => e
    render json: { message: e.message }, status: 500
  end

  respond_to do |format|
    if status > 200
      format.json {
        render json: {
          message: error_message
        }, status: status
      }
    else
      render json: {
        auth_token: JsonWebToken.encode(user.auth_token_payload),
        expires_at: Constants::TOKEN_EXPIRATION_TIME_STR,
        profile: profile
      }, status: 200
    end
  end
end
