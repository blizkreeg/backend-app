class Photo < ActiveRecord::Base
  # include JsonbAttributeHelpers

  belongs_to :profile, foreign_key: "profile_uuid", touch: true

  PUBLIC_ID_LENGTH = 10
  MAX_WIDTH = 1000
  MAX_HEIGHT = 1000
  THUMBNAIL_TRANSFORMATIONS = 'c_fill,g_face:center,r_max'
  PROFILE_TRANSFORMATIONS = 'c_fill,g_face:center,q_50'
  FULLSCREEN_TRANSFORMATIONS = 'c_fill,q_50'

  # scope :valid, -> { where("(properties->>'marked_for_deletion')::boolean = false").order("(case when (properties->>'primary')::boolean = true then '1' else '0' end) desc") }
  scope :approved, -> { with_approved(true) }
  scope :ordered, -> { order("(case when (properties->>'primary')::boolean = true then '1' else '0' end) desc").order("updated_at DESC") }
  scope :primary, -> { where("(properties->>'primary')::boolean = true").order("updated_at DESC") }

  MASS_UPDATE_ATTRIBUTES = %i(
    primary
    reviewed
    approved
  )

  ATTRIBUTES = {
    primary:            :boolean,
    reviewed:           :boolean,
    approved:           :boolean,
    public_id:          :string,
    public_version:     :string,
    marked_for_deletion: :boolean,
    facebook_id:        :string,
    facebook_url:       :string,
    original_url:       :string,
    original_width:     :integer,
    original_height:    :integer,
  }

  # store_accessor :properties, *(ATTRIBUTES.keys.map(&:to_sym))
  # jsonb_attr_helper :properties, ATTRIBUTES
  jsonb_accessor :properties, ATTRIBUTES

  # required
  # validates :public_id, presence: true, unless: lambda { |record| record.properties["facebook_photo_id"].present? }

  before_create :set_defaults
  after_destroy :delete_from_cloudinary

  def self.upload_remote_photo_to_cloudinary(url, options = {})
    xid = SecureRandom.hex(Photo::PUBLIC_ID_LENGTH)
    uploaded_hash = Cloudinary::Uploader.upload(url,
                                                public_id: xid,
                                                transformation: { width: Photo::MAX_WIDTH, height: Photo::MAX_HEIGHT, crop: :limit },
                                                tags: [Rails.env])

    if options[:update_photo_id]
      photo = Photo.find(options[:update_photo_id])
      photo.public_id = uploaded_hash["public_id"]
      photo.public_version = uploaded_hash["version"]
      photo.original_url = uploaded_hash["url"]
      photo.original_width = uploaded_hash["width"]
      photo.original_height = uploaded_hash["height"]
      photo.save!
    end

    uploaded_hash
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Sidekiq: Failed to find photo with id #{options[:update_photo_id]}"
  rescue CloudinaryException
    Rails.logger.error "Sidekiq: Cloudinary upload error. Possibly bad url: #{url}"
  end

  def self.upload_photos_to_cloudinary(profile_uuid)
    profile = Profile.find(profile_uuid)
    profile.photos.each do |photo|
      next if photo.public_id.present?
      next if photo.original_url.blank?

      self.delay.upload_remote_photo_to_cloudinary(photo.original_url, update_photo_id: photo.id)
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Sidekiq: Can't find profile with uuid #{profile_uuid}"
  end

  private

  def set_defaults
    self.primary = false if self.primary.nil?
    self.approved = true
    self.reviewed = false
    self.marked_for_deletion = false

    true
  end

  def delete_from_cloudinary
    Cloudinary::Uploader.destroy(self.public_id, invalidate: true)
  end
end
