module Matchmaker

  DEFAULT_AGE_GAP_MEN   = [-5, 0]
  DEFAULT_AGE_GAP_WOMEN = [0, +5]

  DEFAULT_HEIGHT_GAP_MEN    = [-7, 0]
  DEFAULT_HEIGHT_GAP_WOMEN  = [0, +7]

  def create_between(p1_uuid, p2_uuid)
    profile_one = Profile.find p1_uuid
    profile_two = Profile.find p2_uuid

    initiator_uuid = profile_one.male? ? profile_one.uuid : profile_two.uuid

    match_1 = Match.create_with(initiates_profile_uuid: initiator_uuid)
                      .find_or_create_by(for_profile_uuid: profile_one.uuid, matched_profile_uuid: profile_two.uuid)
    match_2 = Match.create_with(initiates_profile_uuid: initiator_uuid)
                      .find_or_create_by(for_profile_uuid: profile_two.uuid, matched_profile_uuid: profile_one.uuid)

    [match_1, match_2]
  end

  def create_conversation(between_uuids=[])
    Conversation.find_or_create_by_participants!(between_uuids)
  end

  module_function :create_between, :create_conversation
end
