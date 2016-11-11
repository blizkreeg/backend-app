class BrewsController < WebController
  layout 'brews'

  before_action :authenticated?, except: [:homepage]
  before_action :redirect_app_users, only: [:homepage], if: lambda { from_app? }
  before_action :has_brews_in_review?, only: [:index]

  def homepage
    # TODO
    head 404
  end

  def index
    @brews = @current_profile.staff_or_internal ?
                Brew.all :
                Brew
                  .min_desirability_gte((@current_profile.desirability_score || 6) - 1) # show brews just one step down from user
                  .min_desirability_lte(@current_profile.desirability_score || 6) # but not out of their band
                  .min_age_lte(@current_profile.age)
                  .max_age_gte(@current_profile.age)
                  .with_moderation_status('live')
                  .limit(25)

    render 'nobrews' if @brews.blank?
    render 'index' unless performed?
  end

  def new
    @brew ||= Brew.new
  end

  def create
    @brew = Brew.create!(brew_params)
    @brew.brewings.build(profile: @current_profile, host: true)
    @brew.save!

    redirect_to action: 'index'
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

  def welcome_ekcoffee_users
  end

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
      raise "You're not logged in!"
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
    if @current_profile.brews.merge(Brewing.hosts).with_moderation_status('in_review').count > 0
      flash[:message] = "We are reviewing your Brew. Stay tuned!"
    end
  end
end
