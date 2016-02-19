module Constants
  TOKEN_EXPIRATION_TIME = 365.days.from_now
  TOKEN_EXPIRATION_TIME_STR = TOKEN_EXPIRATION_TIME.iso8601

  LATEST_API_VERSION = "1"
  SUPPORTED_API_VERSION = %w(1)

  N_MATCHES_AT_A_TIME = 5

  CLOUDINARY_HOST_URL = 'http://res.cloudinary.com/ekcoffee/image/upload/'

  MIN_AGE = 21
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

  UNMATCH_REASONS = [
    "Not interested anymore",
    "Inappropriate behavior/talk",
    "Feels like spam",
    "Not getting replies"
  ]
end
