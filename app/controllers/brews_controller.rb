class BrewsController < WebController
  layout 'brews'

  helper_method :live_in_user_location?

  WAITLIST_LAUNCH_DATE = Date.new(2017, 1, 31)
  PUBLIC_EXCEPTION_METHODS = [:show]
  WAITLIST_EXCEPTION_METHODS = [:add_to_waitlist, :show_on_waitlist, :update_phone] + PUBLIC_EXCEPTION_METHODS
  NAV_TABS_ONLY_METHODS = [:index, :community, :introductions, :conversations]

  # except for the public pages and (potentially) SEO-able page for brew details,
  # all access should be gated
  before_action :authenticated?, except: PUBLIC_EXCEPTION_METHODS

  # if the user is from the mobile app OR they're an existing user but don't meet the criteria for Brew membership
  # then, show them the "you're on a waitlist" screen
  before_action :show_waitlist_screen?, except: WAITLIST_EXCEPTION_METHODS, if: lambda { user_not_admitted? }

  # mobile nav tabs
  before_action :show_bottom_menu, only: NAV_TABS_ONLY_METHODS, if: lambda { logged_in? && (from_app? || mobile_device?) }

  def index
    @section = 'brews'

    if @current_profile.administrator
      default_brews = Brew
                      .happening_on_after(Time.now.in_time_zone('Asia/Kolkata').to_date - 1.day)
                      .with_moderation_status('live')
    else
      default_brews = Brew
                      .min_desirability_gte((@current_profile.desirability_score || 6) - 1) # show brews just one step down from user
                      .min_desirability_lte(@current_profile.desirability_score || 6) # but not out of their band
                      .min_age_lte(@current_profile.age)
                      .max_age_gte(@current_profile.age)
                      .happening_on_after(Time.now.in_time_zone(@current_profile.time_zone).to_date - 1.day)
                      .with_moderation_status('live')
    end

    @brews = []
    @brews += default_brews.is_hosted_by_ekcoffee.ordered_by_soonest
    @brews += default_brews.not_hosted_by_ekcoffee.ordered_by_soonest

    render 'nobrews' if @brews.blank?
    render 'index' unless performed?
  end

  def new
    @brew ||= Brew.new
  end

  def create
    brew_params[:hosted_by_ekcoffee] = false
    @brew = Brew.create!(brew_params)
    @brew.brewings.build(profile: @current_profile, host: true, status: Brewing::GOING)
    @brew.save!

    NotificationsWorker.delay.notify_admins_of_new_brew(@brew.id)

    redirect_to action: 'index'
  end

  def edit
    @brew = Brew.with_slug(params[:slug]).take
  end

  def update
    @brew = Brew.with_slug(params[:slug]).take
    @brew.update!(brew_params)

    redirect_to brew_path(@brew.slug)
  end

  def show
    @brew = Brew.with_slug(params[:slug]).take
  end

  def register
    @brew = Brew.with_slug(params[:brew_slug]).take
  end

  def registered
    flash[:message] = 'You are going to this Brew!'
    @brew = Brew.with_slug(params[:brew_slug]).take
    brewing = @brew.brewings.where(profile_uuid: @current_profile.uuid).take
    if brewing.present?
      brewing.update!(status: Brewing::GOING)
    else
      @brew.brewings.build(profile: @current_profile, host: false, status: Brewing::GOING)
      @brew.save
    end

    redirect_to brew_path(@brew.slug)
  end

  def show_interest
    @brew = Brew.with_slug(params[:brew_slug]).take
    @brew.brewings.build(profile: @current_profile, host: false, status: Brewing::INTERESTED)
    @brew.save!

    NotificationsWorker.delay.notify_hosts_of_new_rsvp(@brew.id, @current_profile.uuid)

    redirect_to :back
  end

  def conversation
    @brew = Brew.with_slug(params[:brew_slug]).take

    redirect_to action: 'index' unless @current_profile.interested_in_brew?(@brew) || @current_profile.going_to_brew?(@brew)

    @photo_ids_hash = @brew.profiles.inject({}) { |hash, profile| hash[profile.uuid] = profile.photos.primary.take.try(:public_id); hash }
    @names_hash = @brew.profiles.inject({}) { |hash, profile| hash[profile.uuid] = profile.firstname; hash }
  end

  def show_user_activity
  end

  def add_to_waitlist; end

  def show_on_waitlist
    # these are users who had been on the app and
    # if we are showing them a waitlist, it means they are either not approved
    # or have a low desirability score (see show_waitlist_screen?)
    if live_in_user_location? && (@current_profile.created_at <= WAITLIST_LAUNCH_DATE) && @current_profile.low_desirability?
      flash[:message] = "We are making some changes to \
                        ekCoffee in 2017 and are rolling out these changes in a gradual fashion. We \
                        have added you to our waitlist. Please bear with us while we roll this out."
    end

    @low_score_waitlist_size = Profile.desirability_score_lte(Profile::LOW_DESIRABILITY).count
  end

  def update_phone
    @current_profile.update!(phone: params[:phone])

    redirect_to action: :show_on_waitlist and return
  end

  def introductions
    @section = 'introductions'

    asked_for_intros_sql = @current_profile.asked_for_intros.to_sql
    got_intro_requests_sql = @current_profile.got_intro_requests.to_sql

    @profiles = Rails.env.production? ?
                  Profile
                    .visible
                    .of_gender(@current_profile.seeking_gender)
                    .where.not(uuid: @current_profile.uuid)
                    .not_staff
                    .desirability_score_gte(Profile::HIGH_DESIRABILITY)
                    .age_gte(@current_profile.age - 5)
                    .age_lte(@current_profile.age + 5)
                    .where.not(uuid: @current_profile.asked_for_intros.pluck(:to_profile_uuid)) # don't show people i've already asked an intro to
                    .where.not(uuid: @current_profile.got_intro_requests.where("properties->>'mutual' is not NULL").pluck(:by_profile_uuid)) # don't show people who's intro request i've rejected or accepted (mutual NULL)
                    .ordered_by_last_seen
                    .limit(9) :
                  Profile
                    .visible
                    .of_gender(@current_profile.seeking_gender)
                    .where.not(uuid: @current_profile.uuid)
                    .where.not(uuid: @current_profile.asked_for_intros.pluck(:to_profile_uuid))
                    .where.not(uuid: @current_profile.got_intro_requests.where("properties->>'mutual' is not NULL").pluck(:by_profile_uuid))
                    .limit(9)
  end

  def request_introduction
    IntroductionRequest.create!(by: @current_profile, to: Profile.find(params[:to]), made_on: DateTime.now.utc)

    respond_to do |format|
      format.json { render json: { success: true } }
    end
  rescue => e
    respond_to do |format|
      format.json { render json: { success: false } }
    end
  end

  def accept_introduction
    intro = IntroductionRequest.find(params[:id])
    intro.update!(mutual: true)
    Conversation.create!(participant_uuids: [@current_profile.uuid, intro.by.uuid])

    respond_to do |format|
      format.json { render json: { success: true } }
    end
  rescue => e
    respond_to do |format|
      format.json { render json: { success: false } }
    end
  end

  def conversations
    @section = 'conversations'

    @conversations = Conversation.all
  end

  def conversation_with
    @section = 'conversation'

    @conversation = Conversation.with_participant_uuids([@current_profile.uuid, params[:profile_uuid]]).take
    @profile = Profile.find(params[:profile_uuid])
    @photo_ids_hash = [@current_profile, @profile].inject({}) { |hash, profile| hash[profile.uuid] = profile.photos.profile.public_id; hash }
    @names_hash = [@current_profile, @profile].inject({}) { |hash, profile| hash[profile.uuid] = profile.firstname; hash }
  end

  def community
    @section = 'community'

    @interests = Interest.all

    unless @current_profile.interests.exists?
      @interests = Interest.all
    else
      render 'edit_interests'
      return
    end
  end

  def edit_interests
  end

  private

  def brew_params
    attributes = Brew::MASS_UPDATE_ATTRIBUTES
    params.require(:brew).permit(*attributes)
  end

  def authenticated?
    if @current_profile.blank?
      raise ActionController::RoutingError.new('Not Found')
    end
  end

  def show_waitlist_screen?
    if @current_profile.phone.present?
      redirect_to action: :show_on_waitlist and return
    else
      redirect_to action: :add_to_waitlist and return
    end
  end

  def live_in_user_location?
    if Ekc.launched_in?(@current_profile.latitude, @current_profile.longitude)
      true
    else
      false
    end
  end

  def has_brews_in_review?
    if logged_in? && @current_profile.brews.merge(Brewing.hosts).with_moderation_status('in_review').count > 0
      flash[:message] = "We are reviewing your Brew. Stay tuned!"
    end
  end

  def show_bottom_menu
    @show_bottom_menu = true
  end

  def user_not_admitted?
    @current_profile.present? && @current_profile.not_approved_or_low_dscore?
  end
end
