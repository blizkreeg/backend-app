module BrewsHelper
  def post_brew_start_date
    (Time.now.in_time_zone('Asia/Kolkata') + (Brew::POST_BREW_MIN_NUM_DAYS_OUT).days).to_date
  end

  def post_brew_end_date
    (Time.now.in_time_zone('Asia/Kolkata') + (Brew::POST_BREW_MAX_NUM_DAYS_OUT).days).to_date
  end

  def format_date(date)
    date.strftime("%A, %b ") + date.day.ordinalize
  end
end
