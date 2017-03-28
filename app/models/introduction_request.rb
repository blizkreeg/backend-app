class IntroductionRequest < ActiveRecord::Base
  belongs_to :by, foreign_key: "by_profile_uuid", class_name: 'Profile'
  belongs_to :to, foreign_key: "to_profile_uuid", class_name: 'Profile'

  ACCEPTED_MESSAGE = "Good news! We've introduced you and %name. Chat away and find common ground :)"

  ATTRIBUTES = {
    made_on: :date_time,
    responded_on: :date_time,
    mutual: :boolean
  }

  jsonb_accessor :properties, ATTRIBUTES

  def self.from_to(uuid_1, uuid_2)
    self.where(by_profile_uuid: uuid_1, to_profile_uuid: uuid_2).take
  end

  def self.find_between(uuid_1, uuid_2)
    self.where(by_profile_uuid: uuid_1, to_profile_uuid: uuid_2).take || self.where(to_profile_uuid: uuid_1, by_profile_uuid: uuid_2).take
  end

  def self.uuids_passed_on_with(uuid)
    self.where(by_profile_uuid: uuid).with_passed(true).pluck(:to_profile_uuid) + self.where(to_profile_uuid: uuid).with_passed(true).pluck(:by_profile_uuid)
  end

  def from?(uuid)
    self.by_profile_uuid == uuid
  end

  def to?(uuid)
    self.to_profile_uuid == uuid
  end

  def self.accept(id)
    intro = IntroductionRequest.find(id)
    intro.update!(mutual: true)

    message = IntroductionRequest::ACCEPTED_MESSAGE.gsub("%name", intro.by.firstname)
    PushNotifier.delay.record_event(intro.by.uuid, 'conv_open', body: message)
    intro.by.set_mobile_goto!(Rails.application.routes.url_helpers.conversations_path)
  end
end
