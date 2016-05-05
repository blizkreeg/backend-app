class ProfileEventLogWorker
  include Sidekiq::Worker

  def perform(profile_uuid, event_name, params = {})
    unless ProfileEventLog::EVENTS_LOG_STRINGS_MAP.keys.include?(event_name.to_sym)
      EKC.logger.error("Logging event '#{event_name}' for profile -- event doesn't exist!")
      return
    end

    ProfileEventLog.create!(
      profile_uuid: profile_uuid,
      event_name: event_name,
      properties: params.to_json
    )
  end
end
