class Api::V1::ProfilesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]
  before_action :authenticate_user!, except: [:create]

  def sign_in
  end

  def create
    # puts params[:profile].inspect

    properties_hash = Profile.properties_hash_from_fb_auth_hash(params[:profile][:facebook_auth_hash])
    properties_hash.merge!({
      intent: params[:profile][:intent],
      latitude: params[:profile][:latitude],
      longitude: params[:profile][:longitude]
    })

    puts "\n **** PROPERTIES_HASH #{properties_hash}"
    @create_params = ActionController::Parameters.new(properties_hash)

    puts "\n***** STRONG ATTRS #{@create_params.inspect}"
    user = Profile.create!(@create_params)
    puts "___"

    puts user.inspect
    if user
      respond_to do |format|
        format.json {
          render json: { auth_token: JsonWebToken.encode(user.auth_token_payload), expires_at: Constants::TOKEN_EXPIRATION_TIME_STR }, status: 200
        }
      end
    else
      respond_to do |format|
        format.json {
          render json: { message: 'Failed to create user' }, status: 400
        }
      end
    end

  # rescue StandardError
  #   respond_to do |format|
  #     format.json {
  #       render json: { message: 'Failed to create user' }, status: 400
  #     }
  #   end
  end

  def show
  end

  def update
  end

  def destroy
  end

  private

  def profile_params
    @create_params.permit(*Profile::EDITABLE_ATTRIBUTES)
  end
end
