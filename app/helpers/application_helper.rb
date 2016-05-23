module ApplicationHelper
  def current_profile
    @current_profile
  end

  def homescreen_headline
    return 'Complete Basic Details' if @current_profile.incomplete
    return 'Check back soon' unless @current_profile.in_waiting_state?

    if @current_profile.matches.undecided.count > 0
      if config.beta_mode
        return 'Noon tomorrow'
      end

      now = Time.now.in_time_zone(@current_profile.time_zone)

      if (now.hour > Constants::MATCHES_DELIVERED_AT_HOURS.max) && (now.hour <= 23)
        'Noon tomorrow'
      else
        matches_hour = Constants::MATCHES_DELIVERED_AT_HOURS.detect { |hour| hour > now.hour }
        matches_time = Time.new(now.year, now.month, now.day, matches_hour)

        in_hours = (matches_time - now).to_i / 1.hour
        in_mins = ((matches_time - now).to_i/60) % 60

        "#{in_hours}h : #{in_mins}m"
      end
    else
      'Check back soon'
    end
  end

  def homescreen_subheadline
    return 'Your profile is missing a few things' if @current_profile.incomplete
    return "We're finding you new matches" unless @current_profile.in_waiting_state?

    if @current_profile.matches.undecided.count > 0
      config.beta_mode ? 'Check your next match at' : 'More matches coming up'
    else
      "We're hard at work finding you new matches"
    end
  end
end
