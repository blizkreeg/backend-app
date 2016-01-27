class Photo < ActiveRecord::Base
  belongs_to :profile, foreign_key: "profile_uuid"

  scope :valid, -> { where("(properties->>'marked_for_deletion')::boolean = false").order("(case when (properties->>'primary')::boolean = true then '1' else '0' end) desc") }

  EDITABLE_ATTRIBUTES = %i(
    primary
    external_image_id
    marked_for_deletion
  )

  ATTRIBUTES = {
    primary:            :boolean,
    approved:           :boolean,
    external_image_id:  :string,
    marked_for_deletion: :boolean,
    facebook_id:        :string,
    facebook_url:       :string,
    url:                :string,
    width:              :integer,
    height:             :integer,
  }

  jsonb_accessor :properties, ATTRIBUTES

  # required
  # validates :external_image_id, presence: true, unless: lambda { |record| record.properties["facebook_photo_id"].present? }

  before_save :set_defaults

  private

  def set_defaults
    self.primary ||= false
    self.approved ||= true
    self.marked_for_deletion ||= false

    true
  end
end
