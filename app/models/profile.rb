class Profile < ActiveRecord::Base
  # include JsonbAttributeHelpers
  include ProfileAttributeHelpers
  include ProfileStateMachine
  include ProfileMatchesHelper

  # https://libraries.io/rubygems/ar_doc_store/0.0.4
  # since we don't have a serial id column
  # # default_scope { order('created_at ASC') }
  scope :create_order, -> { order('profiles.created_at ASC') }
  scope :inactive, -> { is_inactive }
  scope :active, -> { where("(profiles.properties->>'inactive')::boolean IS NOT TRUE") }
  scope :older_than, -> (age) { age_gte(age) }
  scope :younger_than, -> (age) { age_lte(age) }
  scope :taller_than, -> (height_in) { height_in_gte(height_in) }
  scope :shorter_than, -> (height_in) { height_in_lte(height_in) }
  scope :of_faith, -> (faith) { with_faith(faith) }
  scope :of_faiths, -> (faiths) { where("profiles.properties->>'faith' IN (?)", faiths) }
  scope :of_gender, -> (gender) { with_gender(gender) }

  # seeking
  scope :seeking_older_than, -> (age) { where("(CAST(profiles.properties->>'seeking_minimum_age' AS integer)) <= ?", age) }
  scope :seeking_younger_than, -> (age) { where("(CAST(profiles.properties->>'seeking_maximum_age' AS integer)) >= ?", age) }
  scope :seeking_taller_than, -> (height_in) { where("(CAST(profiles.properties->>'seeking_minimum_height_in' AS integer)) <= ?", height_in) }
  scope :seeking_shorter_than, -> (height_in) { where("(CAST(profiles.properties->>'seeking_maximum_height_in' AS integer)) >= ?", height_in) }
  scope :seeking_of_faith, -> (faith) { where("profiles.properties->'seeking_faith' ? :faith", faith: faith) }
  # scope :seeking_of_gender, -> (gender) { with_gender(gender) } # FUTURE, when opening up to LGBT

  scope :ready_for_matches, -> { where("state = 'waiting_for_matches' OR state = 'waiting_for_matches_and_response'") }
  scope :within_distance, -> (lat, lng, meters=nil) { where("earth_box(ll_to_earth(?, ?), ?) @> ll_to_earth(profiles.search_lat, profiles.search_lng)", lat, lng, meters || Constants::NEAR_DISTANCE_METERS) }
  scope :ordered_by_distance, -> (lat, lng, dir='ASC') { select("*, earth_distance(ll_to_earth(profiles.search_lat,profiles.search_lng), ll_to_earth(#{lat}, #{lng})) as distance").order("distance #{dir}") }

  has_many :social_authentications, primary_key: "uuid", foreign_key: "profile_uuid", autosave: true, dependent: :destroy
  has_one  :facebook_authentication, -> { where(oauth_provider: 'facebook') }, primary_key: "uuid", foreign_key: "profile_uuid"
  has_many :photos, primary_key: "uuid", foreign_key: "profile_uuid", autosave: true, dependent: :destroy
  has_many :matches, primary_key: "uuid", foreign_key: "for_profile_uuid", autosave: true, dependent: :destroy
  has_many :matched_with, class_name: 'Match', primary_key: "uuid", foreign_key: "matched_profile_uuid", autosave: true, dependent: :destroy
  has_many :sent_messages, class_name: 'Message', primary_key: "uuid", foreign_key: "sender_uuid", autosave: true, dependent: :destroy
  has_many :received_messages, class_name: 'Message', primary_key: "uuid", foreign_key: "recipient_uuid", autosave: true, dependent: :destroy
  has_many :conversation_healths, primary_key: "uuid", foreign_key: "profile_uuid", autosave: true, dependent: :destroy
  has_many :real_dates, primary_key: "uuid", foreign_key: "profile_uuid", autosave: true, dependent: :destroy

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
    employer_name
    latitude
    longitude
    last_known_latitude
    last_known_longitude
    intent
    date_preferences
    about_me_i_love
    about_me_ideal_weekend
    about_me_bucket_list
    about_me_quirk
    seeking_minimum_age
    seeking_maximum_age
    seeking_minimum_height
    seeking_maximum_height
    seeking_faith
    disable_notifications_setting
    has_new_queued_matches
  )

  ATTRIBUTES = {
    # basic properties
    email:                        :string,
    firstname:                    :string,
    lastname:                     :string,
    age:                          :integer,
    gender:                       :string,
    born_on_year:                 :integer,
    born_on_month:                :integer,
    born_on_day:                  :integer,
    height:                       :string,
    height_in:                    :integer,
    faith:                        :string,
    earned_degrees:               :string_array,
    highest_degree:               :string,
    schools_attended:             :string_array,
    profession:                   :string,
    employer_name:                :string,
    time_zone:                    :string,
    latitude:                     :decimal,
    longitude:                    :decimal,
    last_known_latitude:          :decimal,
    last_known_longitude:         :decimal,
    intent:                       :string,
    location_city:                :string,
    location_state:               :string,
    location_country:             :string,
    date_preferences:             :string_array,
    about_me_i_love:              :string,
    about_me_ideal_weekend:       :string,
    about_me_bucket_list:         :string,
    about_me_quirk:               :string,
    inactive:                     :boolean,
    inactive_reason:              :string,
    disable_notifications_setting: :boolean,

    # match preferences
    seeking_minimum_age:          :integer,
    seeking_maximum_age:          :integer,
    seeking_minimum_height:       :string,
    seeking_maximum_height:       :string,
    seeking_minimum_height_in:    :integer,
    seeking_maximum_height_in:    :integer,
    seeking_faith:                :string_array,
    # seeking_gender:               :string,

    # internal admin stuff
    incomplete:                   :boolean,
    incomplete_fields:            :string_array,
    possible_relationship_status: :string,
    signed_in_at:                 :date_time,
    signed_out_at:                :date_time,
    substate:                     :string,
    substate_endpoint:            :string,
    butler_conversation_uuid:     :string,
    has_new_queued_matches:       :boolean,

    # matching related
    # attractiveness_score:         :integer, # median of all scores by reviewers?
    # use_of_language_score:        :integer, # objective measure?
    # human_review_score:           :integer, # median of subjective review scores by reviewers?
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
  # jsonb_attr_helper :properties, ATTRIBUTES
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
  validates :seeking_minimum_height, inclusion: { in: Constants::HEIGHT_RANGE }, allow_blank: true
  validates :seeking_maximum_height, inclusion: { in: Constants::HEIGHT_RANGE }, allow_blank: true

  validate :validate_date_preferences

  reverse_geocoded_by :latitude, :longitude do |profile, results|
    if geo = results.first
      profile.location_city = geo.city
      profile.location_state = geo.state
      profile.location_country = geo.country
    end
  end
  after_validation :reverse_geocode, if: ->(profile){ (profile.latitude.present? && profile.latitude_changed?) || (profile.longitude.present? && profile.longitude_changed?) }

  before_save :set_search_latlng, if: Proc.new { |profile| profile.latitude_changed? || profile.longitude_changed? }
  before_save :set_tz, if: Proc.new { |profile| profile.latitude_changed? || profile.longitude_changed? }
  before_save :set_age, if: Proc.new { |profile| profile.born_on_year_changed? || profile.born_on_month_changed? || profile.born_on_day_changed? }
  after_create :signed_up!, if: Proc.new { |profile| profile.none? }
  before_create :set_about_me, if: lambda { Rails.env.development? } # TBD: REMOVE BEFORE PRODUCTION
  before_create :initialize_butler_conversation
  before_save :set_default_seeking_preference, if: Proc.new { |profile| profile.any_seeking_preference_blank? }
  # after_save :add_to_preferences_changed_list, if: Proc.new { |profile| profile.any_seeking_preference_changed? }
  after_update :update_clevertap

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

    def height_in_inches(ft_in_str)
      if ft_in_str.present?
        ft, inches = ft_in_str.split(/['"]/i)
        ht_in = 12 * ft.to_i + inches.to_i
      end

      ht_in
    end

    def push_to_clevertap(uuid)
      profile = Profile.find(uuid)
      payload_body = {
        d: [
          {
            identity: uuid,
            type: 'profile',
            ts: Time.now.to_i,
            profileData: {
              uuid: uuid,
              email: profile.email,
              firstname: profile.firstname,
              lastname: profile.lastname,
              gender: profile.gender,
              location_city: profile.location_city,
              location_country: profile.location_country,
              inactive: profile.inactive,
              incomplete: profile.incomplete,
              "MSG-push" => !profile.disable_notifications_setting
            }
          }
        ]
      }

      Clevertap.post_json('/1/upload', payload_body.to_json)
    rescue ActiveRecord::RecordNotFound
      EKC.logger.error "ERROR: UUID #{uuid} not found. Cannot update Clevertap profile."
    rescue StandardError => e
      EKC.logger.error "ERROR: Failed to update Clevertap profile, exception: #{e.class.name} : #{e.message}"
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

  def seeking_gender
    self.gender == GENDER_MALE ? GENDER_FEMALE : GENDER_MALE
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
    substate_value = self.read_attribute(:substate)
    return substate_value if substate_value.present?

    self.in_conversation? ? self.active_mutual_match.conversation.state : nil
  end

  def any_seeking_preference_blank?
    self.seeking_minimum_age.blank? ||
    self.seeking_maximum_age.blank? ||
    self.seeking_minimum_height.blank? ||
    self.seeking_maximum_height.blank? ||
    self.seeking_faith.blank?
  end

  def any_seeking_preference_changed?
    self.seeking_minimum_age_changed? ||
    self.seeking_maximum_age_changed? ||
    self.seeking_minimum_height_changed? ||
    self.seeking_maximum_height_changed? ||
    self.seeking_faith_changed?
  end

  def test_and_set_primary_photo!
    num_primary = self.photos.primary.count
    return if num_primary == 1 || self.photos.count == 0

    if num_primary == 0
      self.photos.ordered.first.update!(primary: true)
    else
      self.photos.primary[1..-1].each do |photo|
        photo.update!(primary: false)
      end
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

  def validate_date_preferences
    unless self.date_preferences.is_a? Array
      errors.add(:date_preferences, "Date preferences should be a list") and return
    end

    self.date_preferences.each do |date_type|
      errors.add(:date_preferences, "#{date_type} is not a valid date preference") unless Constants::DATE_PREFERENCE_TYPES.include?(date_type)
    end
  end

  def set_about_me
    self.about_me_i_love = (rand > 0.3 ? Faker::Lorem.sentence(10) : nil )
    self.about_me_ideal_weekend = (rand > 0.3 ? Faker::Lorem.sentence(10) : nil )
    self.about_me_bucket_list = (rand > 0.3 ? Faker::Lorem.sentence(8) : nil )
    self.about_me_quirk = (rand > 0.3 ? Faker::Lorem.sentence(6) : nil )
  end

  def initialize_butler_conversation
    self.butler_conversation_uuid = SecureRandom.uuid
  end

  def set_default_seeking_preference
    if self.seeking_minimum_age.blank? && self.age.present?
      self.seeking_minimum_age = Matchmaker.default_min_age_pref(self.gender, self.age)
    end

    if self.seeking_maximum_age.blank? && self.age.present?
      self.seeking_maximum_age = Matchmaker.default_max_age_pref(self.gender, self.age)
    end

    if self.seeking_minimum_height.blank? && self.height.present?
      self.seeking_minimum_height = Matchmaker.default_min_ht_pref(self.gender, self.height)
    end

    if self.seeking_maximum_height.blank? && self.height.present?
      self.seeking_maximum_height = Matchmaker.default_max_ht_pref(self.gender, self.height)
    end

    if self.seeking_faith.blank?
      self.seeking_faith = Matchmaker.default_faith_pref
    end
  end

  def add_to_preferences_changed_list
    puts "pushing #{self.uuid} to 'preferences_updated_profiles'"
    $redis.lpush 'preferences_updated_profiles', self.uuid
  end

  def update_clevertap
    self.class.delay_for(2.seconds).push_to_clevertap(self.uuid)
  end

  def set_search_latlng
    self.search_lat = self.latitude
    self.search_lng = self.longitude
  end
end
