module AdminHelper
  def admin_user
    @admin_user
  end

  def render_event_log(el)
    str = content_tag(:h5, ProfileEventLog::EVENTS_LOG_STRINGS_MAP[el.event_name.to_sym], style: 'font-weight: 600')
    time = render_time(el.created_at, tz: @profile.time_zone)
    str += content_tag(:h6, time.html_safe)
    if el.properties["uuids"].present?
      str += el.properties["uuids"].map do |uuid|
               p = Profile.find(uuid) rescue nil
               content_tag(:a, p.firstname, href: '/url') if p.present?
             end.join(', ').html_safe
    elsif el.properties["uuid"]
      p = Profile.find(el.properties["uuid"]) rescue nil
      str += content_tag(:p, content_tag(:a, p.firstname, href: '/url')) if p.present?
    end

    str
  end

  def render_time(dtime, opts = {})
    opts[:relative] = true if opts[:relative].nil?
    opts[:local] = true if opts[:local].nil?
    opts[:tz] = 'America/Los_Angeles' if opts[:tz].nil?

    time = ''
    if opts[:relative]
      time += "#{distance_of_time_in_words_to_now(dtime)} ago. "
    end

    if opts[:local]
      time += "local: " + dtime.in_time_zone(opts[:tz]).strftime("%c")
    end

    time
  end
end
