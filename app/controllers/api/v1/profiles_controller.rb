class Api::V1::ProfilesController < ApplicationController
  respond_to :json

  PUBLIC_ACCESS_METHODS = [:create, :sign_in, :index, :add_to_waiting_list]
  AUTHORIZATION_NOT_REQUIRED_METHODS = [:create, :sign_in, :index, :add_to_waiting_list, :report, :home]

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

    # associate facebook auth
    @profile.social_authentications.build(
      oauth_uid: facebook_auth_hash[:uid],
      oauth_provider: 'facebook',
      oauth_token: facebook_auth_hash[:credentials][:token],
      oauth_token_expiration: facebook_auth_hash[:credentials][:expires_at],
      oauth_hash: facebook_auth_hash
    )

    # persist
    @profile.save!

    @profile.create_initial_matches

    # set authenticated user
    set_current_profile(@profile)

    render status: 201
  rescue ActiveRecord::RecordNotUnique => e
    EKC.logger.error e.message
    EKC.logger.error e.backtrace.join('\n')

    notify_of_exception(e)
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
  rescue ActiveRecord::RecordNotFound
    respond_with_error("We could not find your account on ekCoffee. Have you signed up first?", 404)
  end

  def show
    @profile = Profile.find(params[:uuid])

    render status: 200
  end

  def update
    @profile = Profile.find(params[:uuid])
    @profile.update!(profile_params)

    render status: 200
  end

  # parameters:
  #   latitude, longitude
  def index
    # TBD: raise exception if show != featured and unless both lat/lon are present
    # TBD: for featured profiles, read from google docs or something else, not database!
    @city = Geocoder.search("#{params[:latitude]}, #{params[:longitude]}").first.city

    found_city = nil
    LIVE_CITIES.each do |city|
      if Geocoder::Calculations.distance_between([params[:latitude], params[:longitude]], [city[:lat], city[:lng]]) * 1_000 <= city[:radius].to_f
        found_city = city
        break
      end
    end

    # TBD: remove
    if Rails.application.config.test_mode
      found_city = @city
    end

    if found_city.blank?
      @profiles = []
    else
      render json: JSON.parse(File.open("#{Rails.root}/db/temp_featured.json", 'r')).to_json.gsub('@city', @city), status: 200
      return
      # @profiles = Profile.within_distance(found_city[:lat], found_city[:lng]).ordered_by_distance(params[:latitude].to_f, params[:longitude].to_f).limit(Constants::N_FEATURED_PROFILES)
    end

    render status: 200
  end

  def destroy
    # TBD: Figure out deletion process
    # Lots of considerations to take into. For instance:
    # - what if this profile has been delivered as a match?
    # - what if this profile is in the middle of a conversation?
    # - what if this profile is delivered as a mutual match?
    @current_profile.update!(inactive: true, marked_for_deletion: true)

    reset_current_profile!

    render 'api/v1/shared/nodata', status: 200
  end

  def add_to_waiting_list
    # TBD: where to maintain the list?

    EKC.logger.info "ADDED TO WAITING LIST lat: #{params[:data][:latitude]}, lon: #{params[:data][:longitude]}, mobile: #{params[:data][:phone]}"

    render status: 200, json: {}
  end

  def report
    # validate:
    # - reported_profile_uuid
    # - reason
    # - match_id

    begin
      reported_profile = Profile.find(params[:data][:reported_profile_uuid])
    rescue ActiveRecord::RecordNotFound => e
      EKC.logger.error("The reported user #{params[:data][:reported_profile_uuid]} was not found!")
      respond_with_error('The reported user was not found', 500)
      return
    end

    # TBD: UNMATCH here
    begin
      match = Match.find(params[:data][:match_id].to_i)
    rescue ActiveRecord::RecordNotFound => e
      EKC.logger.error("The reported match #{params[:data][:match_id].to_i} was not found!")
      respond_with_error('The reported match was not found', 500)
      return
    end

    unless Constants::REPORT_REASONS.include?(params[:data][:reason])
      respond_with_error('Reason for reporting not valid', 500)
      return
    end

    # TBD: file the report somewhere!
    reported_profile.report!(:waiting_for_matches) if reported_profile.in_conversation?
    @current_profile.report!(:waiting_for_matches) if @current_profile.in_conversation?

    ProfileEventLogWorker.perform_async(@current_profile.uuid, :reported_match, uuid: params[:data][:reported_profile_uuid])

    render 'api/v1/shared/nodata', status: 200
  rescue ActiveRecord::RecordNotFound

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

  # TBD: move this to a different controller
  def home
    srand Time.now.to_i

    # TBD: fix before going live!
    @content_type = 'none'# ((rand(10)%3) == 0) ? 'text' : (((rand(10)%3) == 1) ? 'link' : 'none')

    render 'api/v1/shared/home', status: 200
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

    notify_of_exception(exception)
    respond_with_error(@profile.errors.full_messages.join(', '), 400, error_code)
  end
end
