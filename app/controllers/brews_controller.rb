class BrewsController < WebController
  layout 'brews'

  before_action :authenticated?, except: [:homepage, :show]
  before_action :redirect_app_users, only: [:homepage], if: lambda { from_app? }
  before_action :has_brews_in_review?, only: [:index]
  before_action :show_bottom_menu, only: [:index], if: lambda { logged_in? && (from_app? || mobile_device?) }

  def homepage
    # TODO
    head 404
  end

  def index
    if @current_profile.blacklisted?
      @brews = []
    else
      @brews = @current_profile.administrator ?
                  Brew
                    .happening_on_after(Time.now.in_time_zone('Asia/Kolkata').to_date - 1.day)
                    .with_moderation_status('live')
                    .order('updated_at DESC') :
                  Brew
                    .min_desirability_gte((@current_profile.desirability_score || 6) - 1) # show brews just one step down from user
                    .min_desirability_lte(@current_profile.desirability_score || 6) # but not out of their band
                    .min_age_lte(@current_profile.age)
                    .max_age_gte(@current_profile.age)
                    .happening_on_after(Time.now.in_time_zone(@current_profile.time_zone).to_date - 1.day)
                    .with_moderation_status('live')
                    .order('updated_at DESC')
                    .limit(25)
    end

    render 'nobrews' if @brews.blank?
    render 'index' unless performed?
  end

  def new
    @brew ||= Brew.new
  end

  def create
    @brew = Brew.create!(brew_params)
    @brew.brewings.build(profile: @current_profile, host: true, status: Brewing::GOING)
    @brew.save!

    NotificationsWorker.delay.notify_admins_of_new_brew(@brew.id)

    redirect_to action: 'index'
  end

  def edit
    @brew = Brew.find(params[:id])
  end

  def update
    @brew = Brew.find(params[:id])
    @brew.update!(brew_params)

    redirect_to brew_path(@brew)
  end

  def show
    @brew = Brew.find(params[:id])
  end

  def register
    @brew = Brew.find(params[:brew_id])
  end

  def registered
    flash[:message] = 'You are going to this Brew!'
    @brew = Brew.find(params[:brew_id])
    @brew.profiles << @current_profile

    redirect_to action: :show, id: @brew.id
  end

  def show_interest
    @brew = Brew.find(params[:brew_id])
    @brew.brewings.build(profile: @current_profile, host: false, status: Brewing::INTERESTED)
    @brew.save!

    NotificationsWorker.delay.notify_hosts_of_new_rsvp(@brew.id, @current_profile.uuid)

    redirect_to :back
  end

  def show_user_activity
  end

  def welcome_ekcoffee_users; end

  def update_phone
    @current_profile.update!(phone: params[:phone])

    redirect_to action: :index
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
    if @current_profile.phone.present?
      redirect_to action: :index and return
    else
      redirect_to action: :welcome_ekcoffee_users and return
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
