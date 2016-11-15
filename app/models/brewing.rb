class Brewing < ActiveRecord::Base
  belongs_to :profile, foreign_key: "profile_uuid", touch: true
  belongs_to :brew, touch: true

  INTERESTED = 'interested'
  GOING = 'going'

  STATUSES = [INTERESTED, GOING]

  ATTRIBUTES = {
    host: :boolean,
    status: :string
  }

  jsonb_accessor :properties, ATTRIBUTES

  validates :status, inclusion: { in: STATUSES }, allow_nil: false

  scope :hosts, -> { is_host }
  scope :interested, -> { with_status('interested') }
  scope :going, -> { with_status('going') }
end
