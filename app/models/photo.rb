class Photo < ActiveRecord::Base
  belongs_to :profile, foreign_key: "profile_uuid"

  EDITABLE_ATTRIBUTES = %i(
    primary
    external_image_id
  )

  ATTRIBUTES = {
    primary:            :boolean,
    approved:           :boolean,
    external_image_id:  :string
  }

  jsonb_accessor :properties, ATTRIBUTES

  # required
  validates :external_image_id, presence: true

  before_save :set_default_values

  private

  def set_default_values
    self.primary ||= false
    self.approved ||= true
  end
end
