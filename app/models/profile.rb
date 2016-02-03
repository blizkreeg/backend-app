class Profile < ActiveRecord::Base
  # https://libraries.io/rubygems/ar_doc_store/0.0.4
  # https://github.com/devmynd/jsonb_accessor
  # since we don't have a serial id column
  default_scope { order('created_at ASC') }

  has_many :social_authentications, primary_key: "uuid", foreign_key: "profile_uuid", autosave: true, dependent: :destroy
  has_one  :facebook_authentication, -> { where(oauth_provider: 'facebook') }, primary_key: "uuid", foreign_key: "profile_uuid"
  has_many :photos, primary_key: "uuid", foreign_key: "profile_uuid", autosave: true, dependent: :destroy
  has_many :matches, primary_key: "uuid", foreign_key: "for_profile_uuid", autosave: true, dependent: :destroy
  has_many :matched_with, class_name: 'Match', primary_key: "uuid", foreign_key: "matched_profile_uuid", autosave: true, dependent: :destroy

  # has_one :permission, dependent: :destroy, primary_key: "uuid", foreign_key: "profile_uuid"
  # set property tracking flags to 'flags'

  EDITABLE_ATTRIBUTES = %i(
    age
    born_on_year
    born_on_month
    born_on_day
    gender
    height
    faith
    highest_degree
    profession
    latitude
    longitude
    last_known_latitude
    last_known_longitude
    intent
  )

  ATTRIBUTES = {
    email:                :string,
    firstname:            :string,
    lastname:             :string,
    age:                  :integer,
    gender:               :string,
    born_on_year:         :integer,
    born_on_month:        :integer,
    born_on_day:          :integer,
    height:               :string,
    faith:                :string,
    highest_degree:       :string,
    profession:           :string,
    time_zone:            :string,
    latitude:             :decimal,
    longitude:            :decimal,
    last_known_latitude:  :decimal,
    last_known_longitude: :decimal,
    intent:               :string,
    incomplete:           :boolean,
    location_city:        :string,
    location_state:       :string,
    location_country:     :string,
  }

  # store_accessor :properties, *(ATTRIBUTES.keys.map(&:to_sym))

  jsonb_accessor :properties, ATTRIBUTES

  # 4.2: http://apidock.com/rails/ActiveRecord/Attributes/ClassMethods/attribute
  # edge: http://edgeapi.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html
  # attribute :firstname, Type::String.new
  # attribute :lastname, Type::String.new
  # attribute :email, Type::String.new
  # attribute :age, Type::Integer.new

  # required properties
  validates :email, :born_on_year, :born_on_month, :born_on_day, :gender, :latitude, :longitude, :intent, presence: true
  validates :email, email: true, jsonb_uniqueness: true
  validates :born_on_year, numericality: { only_integer: true, less_than_or_equal_to: Date.today.year-Constants::MIN_AGE }
  validates :born_on_month, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 12 }
  validates :born_on_day, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 31 }
  validates :gender, inclusion: { in: %w(male female) }
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validates :intent, inclusion: { in: Constants::INTENTIONS, message: "%{value} is not a valid intent" }

  # optional properties
  validates :faith, inclusion: { in: Constants::FAITHS }, allow_blank: true
  validates :highest_degree, inclusion: { in: Constants::DEGREES }, allow_blank: true
  validates :height, inclusion: { in: Constants::HEIGHT_RANGE }, allow_blank: true
  validates :last_known_latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :last_known_longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  validates :profession, length: { maximum: 50 }, allow_blank: true

  reverse_geocoded_by :latitude, :longitude do |profile, results|
    if geo = results.first
      profile.location_city = geo.city
      profile.location_state = geo.state
      profile.location_country = geo.country
    end
  end
  after_validation :reverse_geocode, if: ->(profile){ (profile.latitude.present? && profile.latitude_changed?) || (profile.longitude.present? && profile.longitude_changed?) }

  before_save :set_tz, if: Proc.new { |profile| profile.latitude_changed? || profile.longitude_changed? }
  before_save :set_age, if: Proc.new { |profile| profile.born_on_year_changed? || profile.born_on_month_changed? || profile.born_on_day_changed? }

  def auth_token_payload
    { 'profile_uuid' => self.uuid }
  end

  class << self
    def properties_derived_from_facebook(auth_hash)
      auth_hash = auth_hash.with_indifferent_access

      dob = Date.parse(auth_hash[:extra][:raw_info][:birthday]) rescue nil
      dob_y, dob_m, dob_d = [dob.year, dob.month, dob.day] rescue [nil, nil, nil]
      degrees_earned = auth_hash[:extra][:raw_info][:education].map { |t| t[:type] } rescue []
      highest_degree_earned =
        if degrees_earned.include? "Graduate School"
          'Masters'
        elsif degrees_earned.include? "College"
          'Bachelors'
        elsif degrees_earned.include? "High School"
          'High School'
        else
          nil
        end
      earned_degrees = auth_hash[:extra][:raw_info][:education].map{} rescue nil
      # TBD: schools
      # schools_attended =

      {
        email: (auth_hash[:info][:email] || auth_hash[:extra][:raw_info][:email] rescue nil),
        firstname: (auth_hash[:info][:first_name] || auth_hash[:extra][:raw_info][:first_name] rescue nil),
        lastname: (auth_hash[:info][:last_name] || auth_hash[:extra][:raw_info][:last_name] rescue nil),
        born_on_year: dob_y,
        born_on_month: dob_m,
        born_on_day: dob_d,
        gender: (auth_hash[:extra][:raw_info][:gender] rescue nil),
        highest_degree: highest_degree_earned,
        profession: (auth_hash[:extra][:raw_info][:work][0][:position][:name] rescue nil)
      }
    end
  end

  def seed_photos_from_facebook(social_authentication)
    # TBD: code smell
    facebook_auth = social_authentication.becomes(FacebookAuthentication)
    primary = true # first photo is primary
    facebook_auth.profile_pictures.each do |photo_hash|
      self.photos.build(
        facebook_id: photo_hash["facebook_photo_id"],
        facebook_url: photo_hash["source"],
        original_url: photo_hash["source"],
        original_width: photo_hash["width"],
        original_height: photo_hash["height"],
        primary: primary
      )
      primary = false
    end
  end

  private

  def set_tz
    timezone = Timezone::Zone.new :latlon => [self.latitude, self.longitude]
    self.time_zone = timezone.zone if ActiveSupport::TimeZone::MAPPING.values.include?(timezone.zone)
    true
  rescue Timezone::Error::NilZone => e
    EKC.logger.error "No timezone was found for user #{self.uuid}, lat,lon: #{self.latitude}, #{self.longitude}"
    true
  end

  def set_age
    self.age = ((Date.today - Date.new(self.born_on_year, self.born_on_month, self.born_on_day))/365).to_i
    true
  end
end
