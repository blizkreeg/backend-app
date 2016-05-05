module AdminHelper
  def admin_user
    @admin_user
  end

  def render_event_log(el)
    str = content_tag(:h5, ProfileEventLog::EVENTS_LOG_STRINGS_MAP[el.event_name.to_sym], style: 'font-weight: 600')
    time = "#{distance_of_time_in_words_to_now(el.created_at)} ago; " +
            "local time: " +
            el.created_at.in_time_zone(@profile.time_zone).strftime("%c")
    str += content_tag(:h6, time)
    if el.properties["uuids"].present?
      str += content_tag(:ul)
      el.properties["uuids"].each do |uuid|
        p = Profile.find(uuid) rescue nil
        str += content_tag(:li, content_tag(:a, p.firstname, href: '/url')) if p.present?
      end
    elsif el.properties["uuid"]
      p = Profile.find(el.properties["uuid"]) rescue nil
      str += content_tag(:li, content_tag(:a, p.firstname, href: '/url')) if p.present?
    end

    str
  end
end
