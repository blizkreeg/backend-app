class Api::V1::ProfilesController < ApplicationController
  respond_to :json

  skip_before_action :verify_authenticity_token, only: [:create, :sign_in, :featured, :add_to_waiting_list]
  before_action :restrict_to_authenticated_clients, except: [:create, :sign_in, :add_to_waiting_list]
  before_action :restrict_to_authenticated_clients, only: [:index], unless: :featured_profiles?
  before_action :validate_json_schema, except: []

  rescue_from ActiveRecord::RecordNotFound, with: :profile_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :validation_error

  def create
    # extract the facebook hash from parameters
    facebook_auth_hash = params[:data][:facebook_auth_hash]
    params[:data].except!(:facebook_auth_hash)

    # create profile
    @profile = Profile.new(profile_params)
    derived_properties = Profile.properties_derived_from_facebook(facebook_auth_hash)
    derived_properties.map { |key, value| @profile.send("#{key}=", derived_properties[key]) }
    @profile.social_authentications.build(
      oauth_uid: facebook_auth_hash[:uid],
      oauth_provider: facebook_auth_hash[:provider],
      oauth_token: facebook_auth_hash[:credentials][:token],
      oauth_token_expiration: facebook_auth_hash[:credentials][:expires_at],
      oauth_hash: facebook_auth_hash
    )
    # load photos from facebook
    @profile.seed_photos_from_facebook(@profile.social_authentications[0])

    @profile.save!

    # set authenticated user
    set_current_profile(@profile)

    render status: 201
  rescue ActiveRecord::RecordNotUnique
    respond_with_error('Profile already exists', 400)
  end

  def sign_in
    facebook_auth_hash = params[:data][:facebook_auth_hash]
    social_auth = SocialAuthentication.where(oauth_uid: facebook_auth_hash[:uid], oauth_provider: facebook_auth_hash[:provider]).take!
    @profile = social_auth.profile

    # set authenticated user
    set_current_profile(@profile)

    render status: 200
  end

  def show
    @profile = Profile.find(params[:uuid])
    render status: 200
  end

  def update
    @profile = Profile.find(params[:uuid])
    @profile.update!(profile_params)
    @profile.reload
    render status: 200
  end

  # parameters:
  #   latitude, longitude
  def index
    # TBD: raise exception if show != featured and unless both lat/lon are present
    # TBD: lookup based on lat/lon
    @city = 'Mumbai'
    @profiles = Profile.limit(3).reorder("RANDOM()")

    render status: 200
  end

  def destroy
  end

  def add_to_waiting_list
    # TBD: where to maintain the list?

    EKC.logger.info "ADDED TO WAITING LIST lat: #{params[:data][:latitude]}, lon: #{params[:data][:longitude]}, mobile: #{params[:data][:phone]}"

    render status: 200, json: {}
  end

  private

  def featured_profiles?
    params[:show] == 'featured'
  end

  def profile_params
    params.require(:data).permit(*Profile::EDITABLE_ATTRIBUTES)
  end

  def profile_not_found
    respond_with_error('Profile not found', 404)
  end

  def validation_error
    respond_with_error(@profile.errors.full_messages.join(', '), 400)
  end
end
