class EventRsvp < ActiveRecord::Base
  belongs_to :profile, foreign_key: "profile_uuid"

  ATTENDING_STATUSES = %w(waitlisted going)

  ATTRIBUTES = {
    ident:              :string,
    attending_status:   :string
  }

  jsonb_accessor :properties, ATTRIBUTES
end
