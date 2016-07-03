module Constants
  TOKEN_EXPIRATION_TIME = 365.days.from_now
  TOKEN_EXPIRATION_TIME_STR = TOKEN_EXPIRATION_TIME.iso8601

  LATEST_API_VERSION = "1"
  SUPPORTED_API_VERSION = %w(1)

  N_FEATURED_PROFILES = 3

  N_FIRST_MATCHES = 2
  N_MATCHES_AT_A_TIME = 1

  CLOUDINARY_HOST_URL = 'http://res.cloudinary.com/ekcoffee/image/upload/'

  NEAR_DISTANCE_METERS = 60_000

  MATCHES_DELIVERED_AT_HOURS = [0, 12, 15, 18, 21]

  MIN_AGE = 18
  FAITHS = %w(
    Agnostic
    Atheist
    Baha'i
    Buddhist
    Christian
    Hindu
    Jain
    Muslim
    Sikh
    Spiritual
    Zoroastrian
    Other
  )
  HEIGHT_RANGE = %w(
    4'0"
    4'1"
    4'2"
    4'3"
    4'4"
    4'5"
    4'6"
    4'7"
    4'8"
    4'9"
    4'10"
    4'11"
    5'0"
    5'1"
    5'2"
    5'3"
    5'4"
    5'5"
    5'6"
    5'7"
    5'8"
    5'9"
    5'10"
    5'11"
    6'0"
    6'1"
    6'2"
    6'3"
    6'4"
    6'5"
    6'6"
    6'7"
    6'8"
    6'9"
    6'10"
    6'11"
  )
  DEGREES = %w(
    Associates/Diploma
    Bachelors
    Masters
    Doctorate
  )
  INTENTIONS = %w(
    Dating
    Relationship
  )
  DATE_PREFERENCE_TYPES = %w(
    Coffee
    Brunch
    Dinner
    Activities
  )

  REPORT_REASONS = [
    "Inappropriate behaviour",
    "Person is married",
    "False information on profile",
    "Feels like spam",
    "Other"
  ]

  DEACTIVATION_REASONS = [
    "I am seeing someone now",
    "I need a break for some time",
    "I'm busy with other things",
    "Other"
  ]

  DELETION_REASONS = [
    "I found someone",
    "I don't like the quality of matches",
    "I'm not meeting enough people",
    "Other"
  ]
end
