namespace :matches do
  desc "generate matches"
  task :generate_new => :environment do
    generate_new_matches
  end

  desc "update state for profiles that have matches"
  task :ready_for_new => :environment do
    send_matches_notifications
  end

  desc "run mutual matches"
  task :find_mutual => :environment do
    puts "[#{EKC.now_in_pacific_time}] -- FINDING MUTUAL MATCHES"
    Profile.active.with_gender('male').where("profiles.state != 'mutual_match' AND profiles.state != 'in_conversation' AND profiles.state != 'waiting_for_matches_and_response'").find_each(batch_size: 10) do |profile|
      profile.matches.mutual.order("matches.created_at ASC").each do |match|
        matched_profile = match.matched_profile
        next if matched_profile.state == 'mutual_match' || matched_profile.state == 'in_conversation'
        next if matched_profile.active_mutual_match.present?

        match.active!
        match.reverse.active!
        match.conversation.open!

        # Matchmaker.transition_to_mutual_match(profile.uuid, match.id)
        puts "[#{EKC.now_in_pacific_time}] -- found mutual match between #{profile.uuid} <> #{matched_profile.uuid}, changing state to 'in_conversation'"

        break
      end
    end
  end

  # -- NOT IN USE --
  def generate_new_matches
    return # disabling matchmaking

    Profile.active.find_each(batch_size: 10) do |profile|
      # NOTE: you cannot make this asynchronous or we could run into a condition where two matches between the same people are being created
      # TODO: room for optimization
      begin
        if profile.visible
          # puts "[#{EKC.now_in_pacific_time}] -- #{profile.uuid} is visible"
          n = Matchmaker.generate_new_matches_for(profile.uuid, onesided: true)
        elsif !profile.blacklisted?
          # puts "[#{EKC.now_in_pacific_time}] -- #{profile.uuid} is not visible"
          n = Matchmaker.generate_new_matches_for(profile.uuid, onesided: true)
        end
        puts "[#{EKC.now_in_pacific_time}] -- #{profile.uuid}: #{n} new matches" if n.present? && (n > 0)
      rescue StandardError => e
        puts "[#{EKC.now_in_pacific_time}] -- error generating matches for #{profile.uuid}, error: #{e.class.name}, message: #{e.message}"
      end
    end
  end

  def send_matches_notifications
    return # no more notifiying of matches, disabling matchmaking

    uuids_to_notify = []
    Profile.active.awaiting_matches.find_each(batch_size: 10) do |profile|
      begin
        if profile.has_queued_matches?
          # check state and if it's time to deliver matches + notify user
          if profile.due_for_new_matches?
            puts "[#{EKC.now_in_pacific_time}] -- #{profile.uuid}: #{[profile.matches.undecided.count, Constants::N_MATCHES_AT_A_TIME].min} new matches"

            case profile.state
            when 'waiting_for_matches'
              profile.new_matches!(:has_matches, Rails.application.routes.url_helpers.v1_profile_matches_path(profile))
            when 'waiting_for_matches_and_response'
              waiting_on_match = profile.active_mutual_match
              profile.new_matches!(:has_matches_and_waiting_for_response, Rails.application.routes.url_helpers.v1_profile_match_path(profile.uuid, waiting_on_match.id))
            end

            if profile.ok_to_send_new_matches_notification?
              PushNotifier.delay.record_event(profile.uuid, 'new_matches', do_not_send_push: true) # no push since we'll send them in batches below
              profile.update!(sent_matches_notification_at: DateTime.now)
              uuids_to_notify << profile.uuid
              puts "[#{EKC.now_in_pacific_time}] -- #{profile.uuid}: sending notification"
            else
              puts "[#{EKC.now_in_pacific_time}] -- #{profile.uuid}: last notification less than a day ago, skipping."
            end
          end
        end
      rescue StandardError => e
        puts "[#{EKC.now_in_pacific_time}] -- error generating matches for #{profile.uuid}, error: #{e.class.name}, message: #{e.message}"
      end
    end

    # send notifications in batches of 100
    uuids_to_notify.each_slice(100) do |uuids|
      PushNotifier.send_transactional_push(uuids, 'new_matches')
    end
  end
end
