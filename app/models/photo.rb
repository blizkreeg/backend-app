class Photo < ActiveRecord::Base
  belongs_to :profile, foreign_key: "profile_uuid"


  PUBLIC_ID_LENGTH = 10
  MAX_WIDTH = 1000
  MAX_HEIGHT = 1000
  THUMBNAIL_TRANSFORMATIONS = 'c_fill,g_face:center,r_max'
  PROFILE_TRANSFORMATIONS = 'c_fill,g_faces:center'
  FULLSCREEN_TRANSFORMATIONS = 'c_fill,g_faces:center'

  scope :valid, -> { where("(properties->>'marked_for_deletion')::boolean = false").order("(case when (properties->>'primary')::boolean = true then '1' else '0' end) desc") }

  MASS_UPDATE_ATTRIBUTES = %i(
    primary
    marked_for_deletion
  )

  ATTRIBUTES = {
    primary:            :boolean,
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

  jsonb_accessor :properties, ATTRIBUTES

  # required
  # validates :public_id, presence: true, unless: lambda { |record| record.properties["facebook_photo_id"].present? }

  before_save :set_defaults

  def self.upload_remote_photo_to_cloudinary(url, options = {})
    xid = SecureRandom.hex(Photo::PUBLIC_ID_LENGTH)
    uploaded_hash = Cloudinary::Uploader.upload(url,
                                                public_id: xid,
                                                transformation: { width: Photo::MAX_WIDTH, height: Photo::MAX_HEIGHT, crop: :limit },
                                                # eager:[
                                                #   { crop: :thumb, gravity: 'face:center', radius: :max },
                                                #   { crop: :crop, gravity: 'faces:center' },
                                                #   { crop: :fill, gravity: 'faces:center' }],
                                                tags: [Rails.env])

    if options[:photo_id]
      photo = Photo.find(options[:photo_id])
      photo.public_id = uploaded_hash["public_id"]
      photo.public_version = uploaded_hash["version"]
      photo.original_url = uploaded_hash["url"]
      photo.original_width = uploaded_hash["width"]
      photo.original_height = uploaded_hash["height"]
      photo.save!
    end

  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Sidekiq: Failed to find photo with id #{options[:photo_id]}"
  rescue CloudinaryException
    Rails.logger.error "Sidekiq: Cloudinary upload error. Possibly bad url: #{url}"
  end

  def self.upload_photos_to_cloudinary(profile_uuid)
    profile = Profile.find(profile_uuid)
    profile.photos.each do |photo|
      next if photo.public_id.present?
      next if photo.original_url.blank?

      self.delay.upload_remote_photo_to_cloudinary(photo.original_url, photo_id: photo.id)
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Sidekiq: Can't find profile with uuid #{profile_uuid}"
  end

  private

  def set_defaults
    self.primary ||= false
    self.approved ||= true
    self.marked_for_deletion ||= false

    true
  end
end
