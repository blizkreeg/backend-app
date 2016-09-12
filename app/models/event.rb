class Event < ActiveRecord::Base
  has_many :event_rsvps

  ATTENDING_STATUSES = %w(waitlisted going)

  ATTRIBUTES = {
    name:               :string,
    place:              :string,
    happening_on:       :date,
    happening_at:       :string,
    address:            :string,
    total_spots:        :integer,
    male_spots:         :integer,
    female_spots:       :integer,
    photo:              :string,
    description:        :string,
    payment_link:       :string,
    min_age:            :integer,
    max_age:            :integer
  }

  ACTIVITES = [
    ['Sunday Brunches', 'sundaybrunch'],
    ['Photography Walks', 'photowalk'],
    ['Local Hikes/Treks', 'localhike'],
    ['Board Games at a Cafe', 'boardgames'],
    ['Dinners', 'dinners'],
    ['Happy Hours/Sundowners', 'happyhours'],
    ['Salsa and Dancing', 'dancing'],
    ['Going to Concerts & Music Venues', 'music'],
    ['Group Cooking Classes', 'cooking']
  ]

  jsonb_accessor :properties, ATTRIBUTES

  scope :current_or_future_events, -> { happening_on_after(Date.today) }

  def self.register_interest_in_experiences(uuid, guest_or_host)
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
