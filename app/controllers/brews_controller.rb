class BrewsController < WebController
  layout 'brews'

  helper_method :live_in_user_location?

  WAITLIST_LAUNCH_DATE = Date.new(2017, 1, 31)
  PUBLIC_EXCEPTION_METHODS = [:show]
  WAITLIST_EXCEPTION_METHODS = [:add_to_waitlist, :show_on_waitlist, :update_phone] + PUBLIC_EXCEPTION_METHODS
  NAV_TABS_ONLY_METHODS = [:index, :community, :introductions, :conversations]
  TRACK_URI_GET_METHODS = [:index, :show, :introductions, :conversations, :conversation_with]

  # except for the public pages and (potentially) SEO-able page for brew details,
  # all access should be gated
  before_action :authenticated?, except: PUBLIC_EXCEPTION_METHODS

  # if the user is from the mobile app OR they're an existing user but don't meet the criteria for Brew membership
  # then, show them the "you're on a waitlist" screen
  before_action :show_waitlist_screen?, except: WAITLIST_EXCEPTION_METHODS, if: lambda { user_not_admitted? }

  # store the path where the user last left off
  before_action :set_goto_uri, only: TRACK_URI_GET_METHODS

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

  # brew details
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

    generated_intros_at = $redis.get("generated_intros_ts:#{@current_profile.uuid}").to_i
    expire_intros_at = generated_intros_at + 24.hours
    last_visited_intro = $redis.get("visited_intros_ts:#{@current_profile.uuid}").to_i
    current_visit_ts = Time.now.utc.to_i
    generated_profile_uuids = JSON.parse($redis.get("generated_intro_profiles:#{@current_profile.uuid}"))

    # generate new intros only if previously generated intros have expired
    generate_new_intros = (generated_intros_at > 0) ? !(current_visit_ts < expire_intros_at) : true

    $redis.set("visited_intros_ts:#{@current_profile.uuid}", Time.now.utc.to_i)

    if generate_new_intros || generated_profile_uuids.blank?
      if generated_profile_uuids.present?
        generated_profile_uuids.each do |uuid|
          request = IntroductionRequest.find_between(@current_profile.uuid, uuid)
          create = false
          if request.blank?
            create = true
          else
            unless request.mutual
              create = true
            end
          end
          if create
            SkippedProfile.find_or_create_by!(by_profile_uuid: @current_profile.uuid, skipped_profile_uuid: uuid)
          end
        end
      end

      @profiles = Matchmaker.introduction_suggestions_for(@current_profile)

      $redis.set("generated_intros_ts:#{@current_profile.uuid}", Time.now.utc.to_i)
      $redis.set("generated_intro_profiles:#{@current_profile.uuid}", @profiles.map(&:uuid).to_json)
    else
      @profiles = Profile.where(uuid: generated_profile_uuids)
    end

    @refresh_time = generated_intros_at > 0 ? [Time.at(expire_intros_at), (Time.now + 24.hours)].min : (Time.now + 24.hours)
  end

  def request_introduction
    IntroductionRequest.where(by: @current_profile, to: Profile.find(params[:to])).first_or_create!(made_on: DateTime.now.utc)

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

    # create a conversation between them
    conversation = Conversation.find_or_create_by_participants!([@current_profile.uuid, intro.by.uuid])
    conversation.update!(introduction_id: intro.id)
    conversation.open!

    # notify the requestor and other bookkeeping
    IntroductionRequest.delay.accept(params[:id])

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

    @conversations = Conversation.participant_uuids_contains(@current_profile.uuid).order("updated_at DESC")
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

  def set_goto_uri
    @current_profile.update(mobile_goto_uri: request.path)
  end

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
