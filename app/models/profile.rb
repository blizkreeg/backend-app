class Profile < ActiveRecord::Base
  include ProfileAttributeHelpers
  include ProfileStateMachine

  # https://libraries.io/rubygems/ar_doc_store/0.0.4
  # https://github.com/devmynd/jsonb_accessor
  # since we don't have a serial id column
  scope :create_order, -> { order('created_at ASC') }
  # default_scope { order('created_at ASC') }

  has_many :social_authentications, primary_key: "uuid", foreign_key: "profile_uuid", autosave: true, dependent: :destroy
  has_one  :facebook_authentication, -> { where(oauth_provider: 'facebook') }, primary_key: "uuid", foreign_key: "profile_uuid"
  has_many :photos, primary_key: "uuid", foreign_key: "profile_uuid", autosave: true, dependent: :destroy
  has_many :matches, primary_key: "uuid", foreign_key: "for_profile_uuid", autosave: true, dependent: :destroy
  has_many :matched_with, class_name: 'Match', primary_key: "uuid", foreign_key: "matched_profile_uuid", autosave: true, dependent: :destroy
  has_many :sent_messages, class_name: 'Message', primary_key: "uuid", foreign_key: "sender_uuid", autosave: true, dependent: :destroy
  has_many :received_messages, class_name: 'Message', primary_key: "uuid", foreign_key: "recipient_uuid", autosave: true, dependent: :destroy
  has_many :conversation_healths, primary_key: "uuid", foreign_key: "profile_uuid", autosave: true, dependent: :destroy
  has_many :meeting_readinesses, primary_key: "uuid", foreign_key: "profile_uuid", autosave: true, dependent: :destroy

  # has_one :permission, dependent: :destroy, primary_key: "uuid", foreign_key: "profile_uuid"
  # set property tracking flags to 'flags'

  MASS_UPDATE_ATTRIBUTES = %i(
    born_on_year
    born_on_month
    born_on_day
    gender
    height
    faith
    highest_degree
    schools_attended
    profession
    latitude
    longitude
    last_known_latitude
    last_known_longitude
    intent
    date_preferences
    about_me_ideal_weekend
    about_me_bucket_list
    about_me_quirk
  )

  ATTRIBUTES = {
    email:                        :string,
    firstname:                    :string,
    lastname:                     :string,
    age:                          :integer,
    gender:                       :string,
    born_on_year:                 :integer,
    born_on_month:                :integer,
    born_on_day:                  :integer,
    height:                       :string,
    faith:                        :string,
    earned_degrees:               :string_array,
    highest_degree:               :string,
    schools_attended:             :string_array,
    profession:                   :string,
    time_zone:                    :string,
    latitude:                     :decimal,
    longitude:                    :decimal,
    last_known_latitude:          :decimal,
    last_known_longitude:         :decimal,
    intent:                       :string,
    incomplete:                   :boolean,
    incomplete_fields:            :string_array,
    location_city:                :string,
    location_state:               :string,
    location_country:             :string,
    date_preferences:             :string_array,
    about_me_ideal_weekend:       :string,
    about_me_bucket_list:         :string,
    about_me_quirk:               :string,
    possible_relationship_status: :string,
    signed_in_at:                 :date_time,
    signed_out_at:                :date_time,
    inactive:                     :boolean,
    inactive_reason:              :string
  }

  EDITABLE_ATTRIBUTES = %i(
    height
    faith
    highest_degree
    schools_attended
    profession
    intent
    date_preferences
    latitude
    longitude
  )

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
  validates :email, jsonb_uniqueness: true
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
  validates :inactive_reason, inclusion: { in: Constants::DEACTIVATION_REASONS, message: "'%{value}' is not valid" }, allow_blank: true, allow_nil: true

  validate :validate_date_preferences

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
  after_create :signed_up!, if: Proc.new { |profile| profile.none? }
  before_create :set_about_me, if: lambda { Rails.env.development? } # TBD: REMOVE BEFORE PRODUCTION

  def auth_token_payload
    { 'profile_uuid' => self.uuid }
  end

  class << self
    def properties_derived_from_facebook(auth_hash)
      auth_hash = auth_hash.with_indifferent_access

      dob = Date.strptime(auth_hash[:info][:birthday], '%m/%d/%Y') rescue nil
      dob_y, dob_m, dob_d = [dob.year, dob.month, dob.day] rescue [nil, nil, nil]
      degree_types = auth_hash[:info][:education].map { |t| t[:type] } rescue []
      highest_degree_earned =
        if degree_types.include? "Graduate School"
          'Masters'
        elsif degree_types.include? "College"
          'Bachelors'
        elsif degree_types.include? "High School"
          'High School'
        else
          nil
        end

      # FB seems to always return this in the order of high school, bachelors, grad school...
      # We want to show in the reverse order
      earned_degrees = auth_hash[:info][:education].map { |t| t[:concentration].try(:[], :name) }.compact.reverse rescue nil
      schools_attended = auth_hash[:info][:education].map { |t| t[:school].try(:[], :name) }.compact.reverse rescue nil

      {
        email: (auth_hash[:info][:email] || auth_hash[:info][:email] rescue nil),
        firstname: (auth_hash[:info][:first_name] || auth_hash[:info][:first_name] rescue nil),
        lastname: (auth_hash[:info][:last_name] || auth_hash[:info][:last_name] rescue nil),
        born_on_year: dob_y,
        born_on_month: dob_m,
        born_on_day: dob_d,
        gender: (auth_hash[:info][:gender] rescue nil),
        highest_degree: highest_degree_earned,
        profession: (auth_hash[:info][:work][0][:position][:name] rescue nil),
        earned_degrees: earned_degrees,
        schools_attended: schools_attended,
        possible_relationship_status: (auth_hash[:info][:relationship_status] rescue nil)
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

  def incomplete
    incomplete_fields.present?
  end

  def incomplete_fields
    fields ||= EDITABLE_ATTRIBUTES.select { |attr_sym| self.send(attr_sym).blank? ? attr_sym : nil }.compact
  end

  def conversations
    Conversation.participant_uuids_contains(self.uuid)
  end

  def initiated_conversation?(conversation)
    self.uuid == conversation.initiator.uuid
  end

  def responding_to_conversation?(conversation)
    self.uuid == conversation.responder.uuid
  end

  def set_next_active!
    # if state is already mutual_match, do nothing
    return if self.mutual_match?

    self.matches.mutual.each do |match|
      next if match.matched_profile.active_mutual_match

      match.update active: true
      match.reverse.update active: true

      # TBD: transition guy's state to mutual match and send push notification to guy.
      return
    end
  end

  def active_mutual_match
    self.matches.active.take
  end

  def substate
    self.in_conversation? ? self.active_mutual_match.conversation.state : nil
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

  def validate_date_preferences
    unless self.date_preferences.is_a? Array
      errors.add(:date_preferences, "Date preferences should be a list") and return
    end

    self.date_preferences.each do |date_type|
      errors.add(:date_preferences, "#{date_type} is not a valid date preference") unless Constants::DATE_PREFERENCE_TYPES.include?(date_type)
    end
  end

  def set_about_me
    self.about_me_ideal_weekend = (rand > 0.3 ? Faker::Lorem.sentence(10) : nil )
    self.about_me_bucket_list = (rand > 0.3 ? Faker::Lorem.sentence(8) : nil )
    self.about_me_quirk = (rand > 0.3 ? Faker::Lorem.sentence(6) : nil )
  end
end
