class ProfileEventLog < ActiveRecord::Base
  default_scope { order("created_at DESC") }

  EVENTS_LOG_STRINGS_MAP = {
    checked_got_no_matches: 'Checked for matches - got none',
    was_delivered_matches: 'Checked out matches',
    viewed_match: 'Viewed match',
    got_mutual_match: 'Got a mutual match',
    unmatched_on: 'Unmatched on',
    got_unmatched: 'Got unmatched by',
    reported_match: 'Reported match',
    started_conversation: 'Started a conversation',
    responded_to_conversation: 'Responded to conversation'
  }
end
