class Api::V1::ProfilesController < ApplicationController
  respond_to :json

  PUBLIC_ACCESS_METHODS = [:create, :sign_in, :index, :add_to_waiting_list]
  AUTHORIZATION_NOT_REQUIRED_METHODS = [:create, :sign_in, :index, :add_to_waiting_list, :report]

  # all actions except these should be restricted to authenticated users
  before_action :authenticated?, except: PUBLIC_ACCESS_METHODS
  # access to list action only if showing featured profiles
  before_action only: [:index] do
    authenticated? unless featured_profiles?
  end
  # should the authenticated user be authorized to do this?
  before_action except: AUTHORIZATION_NOT_REQUIRED_METHODS do
    authorized?(params[:uuid])
  end
  # always validate schema
  before_action :validate_json_schema, except: []

  rescue_from ActiveRecord::RecordNotFound, with: :profile_not_found
  rescue_from ActiveRecord::RecordInvalid, with: lambda { |e| validation_error(e) }

  def create
    # extract the facebook hash from parameters
    facebook_auth_hash = params[:data][:facebook_auth_hash]
    params[:data].except!(:facebook_auth_hash)

    # build profile
    @profile = Profile.new(profile_params)
    derived_properties = Profile.properties_derived_from_facebook(facebook_auth_hash)
    derived_properties.map { |key, value| @profile.send("#{key}=", derived_properties[key]) }

    @profile.social_authentications.build(
      oauth_uid: facebook_auth_hash[:uid],
      oauth_provider: 'facebook',
      oauth_token: facebook_auth_hash[:credentials][:token],
      oauth_token_expiration: facebook_auth_hash[:credentials][:expires_at],
      oauth_hash: facebook_auth_hash
    )

    # load photos from facebook
    @profile.seed_photos_from_facebook(@profile.social_authentications[0])

    @profile.save!

    # set authenticated user
    set_current_profile(@profile)

    Photo.delay.upload_photos_to_cloudinary(@profile.uuid)

    render status: 201
  rescue ActiveRecord::RecordNotUnique => e
    EKC.logger.error e.message
    EKC.logger.error e.backtrace.join('\n')

    respond_with_error('Profile already exists', 400)
  end

  def sign_in
    # TBD: there's a security hole here!!! Someone could fake this payload.
    # TBD: if a required permission was removed, make sure this raises the FB exception
    facebook_auth_hash = params[:data][:facebook_auth_hash]
    social_auth = SocialAuthentication.where(oauth_uid: facebook_auth_hash[:uid], oauth_provider: 'facebook').take!
    social_auth.update!(oauth_token: facebook_auth_hash[:credentials][:token],
                        oauth_token_expiration: facebook_auth_hash[:credentials][:expires_at],
                        oauth_hash: facebook_auth_hash)
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
    # TBD: for featured profiles, read from google docs or something else, not database!
    from_city = Geocoder.search("#{params[:latitude]}, #{params[:longitude]}").first.city

    found_city = nil
    LIVE_CITIES.each do |city|
      if Geocoder::Calculations.distance_between([params[:latitude], params[:longitude]], [city[:lat], city[:lng]]) * 1_000 <= city[:radius].to_f
        found_city = city
        break
      end
    end

    @city = from_city
    if found_city.blank?
      @profiles = []
    else
      @profiles = Profile.within_distance(found_city[:lat], found_city[:lng]).ordered_by_distance(params[:latitude].to_f, params[:longitude].to_f).limit(Constants::N_FEATURED_PROFILES)
    end

    render status: 200
  end

  def destroy
    # TBD: figure this out before going to PROD
    # @profile = Profile.find(params[:uuid])
    # @profile.destroy

    reset_current_profile!

    render 'api/v1/shared/nodata', status: 200
  end

  def add_to_waiting_list
    # TBD: where to maintain the list?

    EKC.logger.info "ADDED TO WAITING LIST lat: #{params[:data][:latitude]}, lon: #{params[:data][:longitude]}, mobile: #{params[:data][:phone]}"

    render status: 200, json: {}
  end

  def report
    # reported_profile_uuid
    # reason
    # match_id

    puts params[:data].inspect

    render 'api/v1/shared/nodata', status: 200
  end

  def get_state
    @profile = Profile.find(params[:uuid])

    render 'api/v1/profiles/state', status: 200
  end

  def sign_out
    @current_profile.update!(signed_out_at: DateTime.now.utc)

    reset_current_profile!

    render 'api/v1/shared/nodata', status: 200
  end

  def activate
    @profile = @current_profile
    @profile.update!(inactive: nil, inactive_reason: nil)

    render 'api/v1/profiles/show', status: 200
  end

  def deactivate
    @profile = @current_profile
    @profile.update!(inactive: true, inactive_reason: params[:data][:reason])

    render 'api/v1/profiles/show', status: 200
  end

  def update_settings
    @profile = @current_profile
    @profile.update!(profile_params)

    render 'api/v1/profiles/show', status: 200
  end

  private

  def featured_profiles?
    params[:show] == 'featured'
  end

  def profile_params
    attributes = Profile::MASS_UPDATE_ATTRIBUTES
    Profile::ATTRIBUTES.each do |attr_name, type|
      attributes.delete(attr_name.to_sym) if type == :array
      attributes += [{ attr_name.to_sym => [] }]
    end
    params.require(:data).permit(*attributes)
  end

  def profile_not_found
    respond_with_error('Profile not found', 404)
  end

  def validation_error(exception)
    if @profile.errors.messages.try(:[], :email).try(:first) == Errors::EMAIL_EXISTS_ERROR_STR
      error_code = 'email_already_exists'
    else
      error_code = nil
    end

    respond_with_error(@profile.errors.full_messages.join(', '), 400, error_code)
  end
end
