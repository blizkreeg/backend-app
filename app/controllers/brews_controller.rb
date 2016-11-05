class BrewsController < WebController
  layout 'brews'

  before_action :authenticated?, except: [:homepage]

  def homepage
  end

  def index
    @brews = Brew
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
    Brew.create!(brew_params)

    redirect_to action: 'index'
  end

  def show
    @brew = Brew.find(params[:id])
  end

  def register
    @brew = Brew.find(params[:brew_id])
  end

  def welcome_ekcoffee_users
  end

  def update_phone
    @current_profile.update!(phone: params[:phone])

    redirect_to action: :index
  end

  private

  def brew_params
    params.require(:brew).permit(:title, :happening_on, :starts_at, :notes)
  end

  def authenticated?
    if @current_profile.blank?
      raise "You're not logged in!"
    end
  end
end
