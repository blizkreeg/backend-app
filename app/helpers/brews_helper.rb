module BrewsHelper
  def show_header
    !@skip_header
  end

  def show_menu?
    @show_bottom_menu
  end

  # FIXME update all instances of Asia/Kolkata to user's time zone
  def post_brew_start_date
    (Time.now.in_time_zone('Asia/Kolkata') + (Brew::POST_BREW_MIN_NUM_DAYS_OUT).days).to_date
  end

  def post_brew_end_date
    (Time.now.in_time_zone('Asia/Kolkata') + (Brew::POST_BREW_MAX_NUM_DAYS_OUT).days).to_date
  end

  def format_date(date)
    if Time.now.in_time_zone('Asia/Kolkata').to_date == date
      if Time.now.in_time_zone('Asia/Kolkata').hour >= 15 # past 3pm
        'Tonight'
      else
        'Today'
      end
    elsif Time.now.in_time_zone('Asia/Kolkata').to_date == (date - 1)
      "Tomorrow, " + date.strftime("%b ") + date.day.ordinalize
    else
      date.strftime("%A, %b ") + date.day.ordinalize
    end
  end

  def format_time(decimal_hour)
    if(decimal_hour >= 12 && decimal_hour < 13)
      suffix = 'pm'
    elsif(decimal_hour >= 13)
      decimal_hour = decimal_hour - 12
      suffix = 'pm'
    else
      suffix = 'am'
    end

    hour = decimal_hour.floor
    min = (decimal_hour % hour) * 60

    hour.to_s + ':' + ('%02d' % min) + ' ' + suffix
  end

  def index_page_heading
    [
      # 'Which Brew is your beat?',
      'Which one will you go to?',
      'Which Brew will you be at?',
      'Meet new people today.',
      'Meet new people.',
      'Get offline. Do stuff. Socialize.',
      # 'Go forth. Be fearless.'
    ].sample
  end

  def nudges
    [
      { mdl_icon: 'group', text: "Make it more fun &amp; ask a friend to join!" },
      { mdl_icon: 'face', text: "Not sure what kind of people will come? Only members verified by us!" }
    ]
  end

  def names_snippet(brew)
    if brew.profiles.count >= 3
      str = brew.profiles.first(2).map(&:firstname).join(', ')
      str += ", and #{brew.profiles.count - 2} more"
    else
      str = brew.profiles.first(2).map(&:firstname).join(' and ')
    end

    str
  end

  def going_snippet(brew)
    going = [' ']

    if brew.profiles.count == 1
      going << 'is'
    else
      going << 'are'
    end

    if brew.tipped?
      going << 'going'
    else
      going << 'interested'
    end

    going.join(' ')
  end

  def places_remaining(brew)
    num = brew.places_remaining_for_gender(current_profile.gender)
    if num > 1
      nil # "#{num} places left."
    elsif num == 1
      '' # "Almost full, 1 place left."
    else
      nil
      # "Oh no, this Brew is full. &#x1f61e;"
    end
  end

  def notice(brew)
    ''
    # user_time = Time.now.in_time_zone(current_profile.time_zone)
    # distance_of_time_in_words(user_time, brew.happening_at) + " left"
  end
end
