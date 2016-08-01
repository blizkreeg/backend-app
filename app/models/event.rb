class Event < ActiveRecord::Base
  has_many :event_rsvps

  ATTENDING_STATUSES = %w(waitlisted going)

  ATTRIBUTES = {
    place:              :string,
    happening_on:       :date,
    happening_at:       :string,
    address:            :string,
    total_spots:        :integer,
    male_spots:         :integer,
    female_spots:       :integer,
    photo:              :string,
    description:        :string
  }

  jsonb_accessor :properties, ATTRIBUTES

  def self.current_or_future_events
    all.select { |event| event.happening_on >= Date.today  }
  end

  def attending
    event_rsvps.map(&:profile)
  end

  def rsvp_for(profile)
    event_rsvps.where(profile_uuid: profile.uuid).take
  end

  def spots_remaining(profile)
    profile.male? ? (male_spots - male_rsvped.count) : (female_spots - female_rsvped.count)
  end

  def male_rsvped
    self.event_rsvps.map(&:profile).flatten.select { |profile| profile.male? }
  end

  def female_rsvped
    self.event_rsvps.map(&:profile).flatten.select { |profile| profile.female? }
  end
end
