# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

NUM_USERS = 100
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

Profile.create!(email: 'vinthanedar@gmail.com',
                firstname: 'Vineet',
                lastname: 'Thanedar',
                gender: 'Male',
                born_on_year: 1980,
                born_on_month: 9,
                born_on_day: 9,
                latitude: 18.96670,
                longitude: 72.83330,
                intent: Constants::INTENTIONS[rand(2)],
                height: "5'11\""
              )

NUM_USERS.times do |idx|
  Profile.create!(
    email: Forgery(:internet).email_address,
    firstname: Faker::Name.first_name,
    lastname: Faker::Name.last_name,
    gender: Forgery('personal').gender,
    born_on_year: BORN_ON_YEARS[rand(BORN_ON_YEARS.size)],
    born_on_month: month = BORN_ON_MONTHS[rand(BORN_ON_MONTHS.size)],
    born_on_day: 1 + rand(BORN_ON_MONTH_DAYS[month.to_s]),
    latitude: Forgery(:geo).latitude,
    longitude: Forgery(:geo).longitude,
    intent: Constants::INTENTIONS[rand(2)],
    height: Constants::HEIGHT_RANGE[rand(Constants::HEIGHT_RANGE.size)]
  )
end
