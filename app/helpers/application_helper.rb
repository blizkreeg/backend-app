module ApplicationHelper
  def current_profile
    @current_profile
  end

  def homescreen_headline
    return 'Complete Basic Details' if @current_profile.incomplete

    if @current_profile.in_match_waiting_state?
      if @current_profile.matches.undecided.count > 0
        if config.beta_mode
          return 'Noon tomorrow'
        end

        now = Time.now.in_time_zone(@current_profile.time_zone)

        if (now.hour >= Constants::MATCHES_DELIVERED_AT_HOURS.max) && (now.hour <= 23)
          return 'Noon tomorrow'
        else
          matches_hour = Constants::MATCHES_DELIVERED_AT_HOURS.detect { |hour| hour > now.hour }
          matches_time = Time.new(now.year, now.month, now.day, matches_hour)

          in_hours = (matches_time - now).to_i / 1.hour
          in_mins = ((matches_time - now).to_i/60) % 60

          return "#{in_hours}h : #{in_mins}m"
        end
      else
        return 'While you wait...'
      end
    elsif @current_profile.in_match_queued_state?
      return 'Loading your matches...'
    else
      return ''
    end
  end

  def homescreen_subheadline
    return 'Your profile is missing a few things' if @current_profile.incomplete

    if @current_profile.in_match_waiting_state?
      if @current_profile.matches.undecided.count > 0
        return (config.beta_mode ? 'Check your next match at' : 'More matches coming up')
      else
        return "We're hard at work finding you new matches"
      end
    elsif @current_profile.in_match_queued_state?
      return 'You have new matches'
    else
      return 'Loading...'
    end
  end
end
