class BrewsController < WebController
  layout 'brews', except: [:homepage]

  WAITLIST_LAUNCH_DATE = Date.new(2017, 1, 30)

  before_action :authenticated?, except: [:homepage, :add_to_invite_list, :show, :partnerships, :membership]
  before_action :redirect_app_users, except: [:add_to_waitlist, :show_on_waitlist, :update_phone], if: lambda { from_app? }
  before_action :has_brews_in_review?, only: [:index]
  before_action :show_bottom_menu, only: [:index], if: lambda { logged_in? && (from_app? || mobile_device?) }

  def homepage
    unless Rails.env.production?
      render 'pages/homepage', layout: 'homepage'
      return
    end

    if request.host == 'ekcoffee.com'
      render 'pages/homepage', layout: 'homepage'
      return
    else
      head 404
    end
  end

  def add_to_invite_list
    NotificationsMailer.delay.new_brew_invite_signup(params[:invite_to])

    render text: 'OK'
  end

  def index
    if @current_profile.not_approved_or_low_dscore?
      render 'nobrews'
      return
    end

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

  def show_user_activity
  end

  def add_to_waitlist; end

  def show_on_waitlist
    # these are users who had been on the app and
    # if we are showing them a waitlist, it means they are either not approved
    # or have a low desirability score (see redirect_app_users)
    # if @current_profile.created_at <= WAITLIST_LAUNCH_DATE
    #   flash[:message] = "#{@current_profile.firstname}, we are making some changes to \
    #                     ekCoffee in 2017. We are rolling out these changes in a gradual fashion. We \
    #                     have added you to our waitlist. Please bear with us while we roll this out."
    # end

    # we've assigned this person a score and it's low so we don't want to admit them
    if @current_profile.desirability_score.present? && (@current_profile.desirability_score <= 6)
      @total_on_list = Profile.desirability_score_lte(6).count
    end
  end

  def update_phone
    @current_profile.update!(phone: params[:phone])

    redirect_app_users
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

  def redirect_app_users
    # TBD - if not launched in their city, show screen
    if @current_profile.phone.present?
      if @current_profile.created_at >= WAITLIST_LAUNCH_DATE && @current_profile.not_approved_or_low_dscore?
        redirect_to action: :show_on_waitlist and return
      else
        redirect_to action: :index and return
      end
    else
      redirect_to action: :add_to_waitlist and return
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
end
