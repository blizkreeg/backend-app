module ApplicationHelper
  def current_profile
    @current_profile
  end

  def homescreen_headline
    if @current_profile.incomplete
      return 'Complete Basic Details'
    elsif @current_profile.phone.present?
      return 'Met someone at a Brew?'
    else
      return 'BREW'
    end

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
          matches_time = Time.new(now.year, now.month, now.day, matches_hour, 0, 0, now.utc_offset)

          in_hours = (matches_time - now).to_i / 1.hour
          in_mins = ((matches_time - now).to_i/60) % 60

          return "#{in_hours}h : #{in_mins}m"
        end
      else
        return 'Hold tight!'
      end
    elsif @current_profile.in_match_queued_state?
      return 'Loading your matches...'
    else
      return ''
    end
  end

  def homescreen_subheadline
    if @current_profile.incomplete
      return 'Your profile is missing a few things'
    elsif @current_profile.phone.present?
      return "We'll match you after the Brew"
    else
      return 'Introducing,'
    end

    if @current_profile.in_match_waiting_state?
      if @current_profile.matches.undecided.count > 0
        return (config.beta_mode ? 'Check your next match at' : 'Get your next match in...')
      else
        return "We're finding you new matches"
      end
    elsif @current_profile.in_match_queued_state?
      return 'You have new matches'
    else
      return 'Loading...'
    end
  end

  def percent_val(n, total)
    return nil unless total > 0

    ((n.to_f / total) * 100).round(1)
  end

  def mobile_device?
    @mobile_device
  end
end
