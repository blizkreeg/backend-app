class EventRsvp < ActiveRecord::Base
  belongs_to :profile, foreign_key: "profile_uuid"
  belongs_to :event

  ATTENDING_STATUSES = %w(waitlisted going)

  ATTRIBUTES = {
    attending_status:   :string,
    ambassador: :boolean
  }

  jsonb_accessor :properties, ATTRIBUTES
end
