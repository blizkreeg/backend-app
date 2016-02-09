require 'csv'

# Read in lat/lon of selected cities
# source: https://tuxworld.wordpress.com/2010/03/23/latitiude-longitude-altitude-for-all-over-india-cities/
cities_ind_mh = CSV.read File.join(Rails.root, "db", "cities_IND_MH.csv")

NUM_USERS = 25
BORN_ON_YEARS = (1960..Date.today.year-21).to_a
BORN_ON_MONTHS = (1..12).to_a
BORN_ON_MONTH_DAYS = {
                      '1' => 31,
                      '2' => 28,
                      '3' => 31,
                      '4' => 30,
                      '5' => 31,
                      '6' => 30,
                      '7' => 31,
                      '8' => 31,
                      '9' => 30,
                      '10' => 31,
                      '11' => 30,
                      '12' => 31,
                      }

Faker::Config.locale = 'en-IND'

# Profile.create!(email: 'vinthanedar@gmail.com',
#                 firstname: 'Vineet',
#                 lastname: 'Thanedar',
#                 gender: 'Male',
#                 born_on_year: 1980,
#                 born_on_month: 9,
#                 born_on_day: 9,
#                 latitude: 18.96670,
#                 longitude: 72.83330,
#                 intent: Constants::INTENTIONS[rand(2)],
#                 height: "5'11\""
#               )

NUM_USERS.times do |idx|
  profile = Profile.create!(
    email: Forgery(:internet).email_address,
    firstname: Faker::Name.first_name,
    lastname: Faker::Name.last_name,
    gender: Forgery('personal').gender.downcase,
    born_on_year: BORN_ON_YEARS[rand(BORN_ON_YEARS.size)],
    born_on_month: month = BORN_ON_MONTHS[rand(BORN_ON_MONTHS.size)],
    born_on_day: 1 + rand(BORN_ON_MONTH_DAYS[month.to_s]),
    latitude: cities_ind_mh[rand(cities_ind_mh.size)][1], #Forgery(:geo).latitude,
    longitude: cities_ind_mh[rand(cities_ind_mh.size)][2], #Forgery(:geo).longitude,
    intent: Constants::INTENTIONS[rand(2)],
    date_preferences: Constants::DATE_PREFERENCE_TYPES.sample(2),
    height: Constants::HEIGHT_RANGE[rand(Constants::HEIGHT_RANGE.size)],
    profession: Faker::Company.profession.camelize,
    highest_degree: Constants::DEGREES[rand(Constants::DEGREES.size)],
    schools_attended: rand(3).times.map { Faker::University.name },
    about_me_ideal_weekend: (rand > 0.3 ? Faker::Lorem.sentence(10) : nil ),
    about_me_bucket_list: (rand > 0.3 ? Faker::Lorem.sentence(8) : nil ),
    about_me_quirk: (rand > 0.3 ? Faker::Lorem.sentence(6) : nil ),
  )
  num_photos = 1 + rand(3)
  w = 400 + rand(400)
  h = 300 + rand(300)
  primary = rand(num_photos)
  bg = Faker::Color.hex_color[1..-1]
  type = %w(jpg png)[rand(2)]
  photos_array = num_photos.times.map.with_index { |i, idx|
                    {
                      original_width: w,
                      original_height: h,
                      primary: (idx == primary),
                      original_url: Faker::Placeholdit.image("#{w}x#{h}", type, bg, 'ffffff', 'photo')
                    }
                 }
  profile.photos.create! photos_array
  profile.reload

  Photo.delay.upload_photos_to_cloudinary(profile.uuid)
end
