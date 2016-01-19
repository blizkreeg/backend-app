class Profile < ActiveRecord::Base
  # https://libraries.io/rubygems/ar_doc_store/0.0.4
  # https://github.com/devmynd/jsonb_accessor
  # since we don't have a serial id column
  default_scope { order('created_at ASC') }

  has_many :social_authentications, primary_key: "uuid", foreign_key: "profile_uuid", autosave: true, dependent: :destroy
  has_many :photos, primary_key: "uuid", foreign_key: "profile_uuid", dependent: :destroy

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
    # facebook_auth_hash
    last_known_latitude
    last_known_longitude
    intent
  )

  ATTRIBUTES = {
    email:          :string,
    firstname:      :string,
    lastname:       :string,
    age:            :integer,
    gender:         :string,
    born_on_year:   :integer,
    born_on_month:  :integer,
    born_on_day:    :integer,
    height:         :string,
    faith:          :string,
    highest_degree: :string,
    profession:     :string,
    time_zone:      :string,
    latitude:       :decimal,
    longitude:      :decimal,
    last_known_latitude: :decimal,
    last_known_longitude: :decimal,
    intent:         :string
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
  validates :intent, inclusion: { in: Constants::INTENTIONS }

  # optional properties
  validates :faith, inclusion: { in: Constants::FAITHS }, allow_blank: true
  validates :highest_degree, inclusion: { in: Constants::DEGREES }, allow_blank: true
  validates :height, inclusion: { in: Constants::HEIGHT_RANGE }, allow_blank: true
  validates :last_known_latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :last_known_longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  validates :profession, length: { maximum: 50 }, allow_blank: true

  before_save :set_tz, if: Proc.new { |profile| profile.latitude_changed? || profile.longitude_changed? }

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

  private

  def set_tz
    timezone = Timezone::Zone.new :latlon => [self.latitude, self.longitude]
    self.time_zone = timezone.zone if ActiveSupport::TimeZone::MAPPING.values.include?(timezone.zone)
  rescue Timezone::Error::NilZone => e
    EKC.logger.error "No timezone was found for user #{self.uuid}, lat: #{self.latitude}, long: #{self.longitude}"
    true
  end
end
