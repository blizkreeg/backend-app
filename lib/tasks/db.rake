# require 'csv'

# # Read in lat/lon of selected cities
# # source: https://tuxworld.wordpress.com/2010/03/23/latitiude-longitude-altitude-for-all-over-india-cities/
# CITIES_IND_MH = CSV.read File.join(Rails.root, "db", "cities_IND_MH.csv")

# NUM_USERS = ENV['USERS'] || 100000
# BORN_ON_YEARS = (1960..Date.today.year-21).to_a
# BORN_ON_MONTHS = (1..12).to_a
# BORN_ON_MONTH_DAYS = {
#                       '1' => 31,
#                       '2' => 28,
#                       '3' => 31,
#                       '4' => 30,
#                       '5' => 31,
#                       '6' => 30,
#                       '7' => 31,
#                       '8' => 31,
#                       '9' => 30,
#                       '10' => 31,
#                       '11' => 30,
#                       '12' => 31,
#                       }

# Faker::Config.locale = 'en-IND'

# NUM_PLACES = 25
# NUM_PHOTOS = 6

# namespace :db do
#   namespace :seed do
#     task :users => :environment do
#       CSV.open(File.join('/tmp', 'import_users.csv'), "wb") do |csv|
#         NUM_USERS.times do |idx|
#           city_idx = rand(CITIES_IND_MH.size)
#           loc_city = CITIES_IND_MH[rand(CITIES_IND_MH.size)][0]
#           loc_state = 'Maharashtra'
#           loc_country = 'India'
#           lat = CITIES_IND_MH[rand(CITIES_IND_MH.size)][1]
#           lng = CITIES_IND_MH[rand(CITIES_IND_MH.size)][2]

#           properties = {
#             email: Forgery(:internet).email_address,
#             firstname: Faker::Name.first_name,
#             lastname: Faker::Name.last_name,
#             gender: gender = Forgery('personal').gender.downcase,
#             born_on_year: by = BORN_ON_YEARS[rand(BORN_ON_YEARS.size)],
#             born_on_month: bm = BORN_ON_MONTHS[rand(BORN_ON_MONTHS.size)],
#             born_on_day: bd = (1 + rand(BORN_ON_MONTH_DAYS[bm.to_s])),
#             location_city: loc_city,
#             location_state: loc_state,
#             location_country: loc_country,
#             latitude: lat, #Forgery(:geo).latitude,
#             longitude: lng, #Forgery(:geo).longitude,
#             intent: Constants::INTENTIONS[rand(2)],
#             faith: Constants::FAITHS[rand(Constants::FAITHS.size)],
#             date_preferences: Constants::DATE_PREFERENCE_TYPES.sample(2),
#             height: ht = Constants::HEIGHT_RANGE[rand(Constants::HEIGHT_RANGE.size)],
#             height_in: Profile.height_in_inches(ht),
#             profession: Faker::Company.profession.camelize,
#             highest_degree: Constants::DEGREES[rand(Constants::DEGREES.size)],
#             employer_name: Faker::Company.name,
#             schools_attended: rand(3).times.map { Faker::University.name },
#             about_me_i_love: (rand > 0.3 ? Faker::Lorem.sentence(10) : nil ),
#             about_me_ideal_weekend: (rand > 0.3 ? Faker::Lorem.sentence(10) : nil ),
#             about_me_bucket_list: (rand > 0.3 ? Faker::Lorem.sentence(8) : nil ),
#             about_me_quirk: (rand > 0.3 ? Faker::Lorem.sentence(6) : nil ),
#             butler_conversation_uuid: SecureRandom.uuid,
#             time_zone: 'Asia/Kolkata',
#             age: age = ((Date.today - Date.new(by, bm, bd))/365).to_i,
#             seeking_minimum_age: Matchmaker.default_min_age_pref(gender, age),
#             seeking_maximum_age: Matchmaker.default_max_age_pref(gender, age),
#             seeking_minimum_height: sminh = Matchmaker.default_min_ht_pref(gender, ht),
#             seeking_maximum_height: smaxh = Matchmaker.default_max_ht_pref(gender, ht),
#             seeking_faith: Matchmaker.default_faith_pref,
#             seeking_minimum_height_in: Profile.height_in_inches(sminh),
#             seeking_maximum_height_in: Profile.height_in_inches(smaxh)
#           }

#           state = 'waiting_for_matches'

#           csv << [properties.to_json, state, DateTime.now.utc, DateTime.now.utc]

#           # profile = Profile.create!(
#           #   email: Forgery(:internet).email_address,
#           #   firstname: Faker::Name.first_name,
#           #   lastname: Faker::Name.last_name,
#           #   gender: Forgery('personal').gender.downcase,
#           #   born_on_year: BORN_ON_YEARS[rand(BORN_ON_YEARS.size)],
#           #   born_on_month: month = BORN_ON_MONTHS[rand(BORN_ON_MONTHS.size)],
#           #   born_on_day: 1 + rand(BORN_ON_MONTH_DAYS[month.to_s]),
#           #   latitude: CITIES_IND_MH[rand(CITIES_IND_MH.size)][1], #Forgery(:geo).latitude,
#           #   longitude: CITIES_IND_MH[rand(CITIES_IND_MH.size)][2], #Forgery(:geo).longitude,
#           #   intent: Constants::INTENTIONS[rand(2)],
#           #   date_preferences: Constants::DATE_PREFERENCE_TYPES.sample(2),
#           #   height: Constants::HEIGHT_RANGE[rand(Constants::HEIGHT_RANGE.size)],
#           #   profession: Faker::Company.profession.camelize,
#           #   highest_degree: Constants::DEGREES[rand(Constants::DEGREES.size)],
#           #   schools_attended: rand(3).times.map { Faker::University.name },
#           #   about_me_ideal_weekend: (rand > 0.3 ? Faker::Lorem.sentence(10) : nil ),
#           #   about_me_bucket_list: (rand > 0.3 ? Faker::Lorem.sentence(8) : nil ),
#           #   about_me_quirk: (rand > 0.3 ? Faker::Lorem.sentence(6) : nil ),
#           # )
#           # num_photos = 1 + rand(1)
#           # w = 400 + rand(400)
#           # h = 300 + rand(300)
#           # primary = rand(num_photos)
#           # bg = Faker::Color.hex_color[1..-1]
#           # type = %w(jpg png)[rand(2)]
#           # photos_array = num_photos.times.map.with_index { |i, idx|
#           #                   {
#           #                     original_width: w,
#           #                     original_height: h,
#           #                     primary: (idx == primary),
#           #                     original_url: Faker::Placeholdit.image("#{w}x#{h}", type, bg, 'ffffff', 'photo')
#           #                   }
#           #                }
#           # profile.photos.create! photos_array
#           # profile.reload

#           # Photo.delay.upload_photos_to_cloudinary(profile.uuid)
#         end
#       end
#     end

#     task :photos => :environment do
#       srand(Time.now.to_i)

#       type = 'avatar' # or 'placeholder'

#       w = 400 + rand(400)
#       h = 300 + rand(300)
#       format = 'jpg'

#       photos_array = NUM_PHOTOS.times.map { |i|
#                         bg = (type == 'avatar')? %w(bg1 bg2)[rand(2)] : Faker::Color.hex_color[1..-1]
#                         set = %w(set1 set2 set3)[rand(3)] if type == 'avatar'
#                         url = (type == 'avatar') ? Faker::Avatar.image(nil, "#{w}x#{h}", format, set, bg) : Faker::Placeholdit.image("#{w}x#{h}", format, bg, 'ffffff', 'photo')

#                         {
#                           original_width: w,
#                           original_height: h,
#                           original_url: url
#                         }
#                      }


#       photos_array.each do |photo_hash|
#         xid = SecureRandom.hex(Photo::PUBLIC_ID_LENGTH)
#         uploaded_hash = Cloudinary::Uploader.upload(photo_hash[:original_url],
#                                                     public_id: xid,
#                                                     transformation: { width: Photo::MAX_WIDTH, height: Photo::MAX_HEIGHT, crop: :limit },
#                                                     tags: [Rails.env, 'seed'])

#         puts "uploaded photo #{uploaded_hash['url']}"

#         photo_hash[:public_id] = uploaded_hash["public_id"]
#         photo_hash[:public_version] = uploaded_hash["version"]
#         photo_hash[:original_url] = uploaded_hash["url"]
#       end

#       CSV.open(File.join('/tmp', 'import_photos.csv'), "wb") do |csv|
#         Profile.limit(50).each do |profile|
#           n_photos = 1 + rand(6)
#           p_array = photos_array.sample(n_photos)
#           p_array[rand(n_photos)][:primary] = true

#           p_array.each do |photo_hash|
#             csv << [photo_hash.to_json, profile.uuid, DateTime.now.utc, DateTime.now.utc]
#           end
#         end
#       end
#     end

#     task :places => :environment do
#       NUM_PLACES.times do |idx|
#         DatePlace.create!(
#           name: Forgery('name').company_name,
#           street_address: Faker::Address.street_address,
#           latitude: 18.98,
#           longitude: 72.83,
#           part_of_city: 'Bandra',
#           city: 'Mumbai',
#           state: 'Maharashtra',
#           country: 'India',
#           price_range: (1+rand(3)).times.map{ '$' }.join,
#           date_types: Constants::DATE_PREFERENCE_TYPES[0..(1+rand(3))]
#         )
#       end
#     end

#     task :posts => :environment do
#       ActiveRecord::Base.connection.execute("TRUNCATE posts") unless Rails.env.production?

#       100.times do
#         post = Post.new
#         post.post_type = [Post::IMAGE_TYPE, Post::VIDEO_TYPE, Post::ARTICLE_TYPE].sample
#         post.title = Forgery(:lorem_ipsum).words(5 + rand(10))
#         post.posted_on = Time.now + ((-50..50).to_a.sample).days
#         if post.image?
#           post.excerpt = rand(10) % 2 == 0 ? Forgery(:lorem_ipsum).words(10 + rand(50)) : nil
#           post.image_public_id = 'MEN_it_s_time_to_up_ou_da_vinci_1_ssz21r'
#         end
#         if post.video?
#           post.image_public_id = '_MG_0580_uvtgbb'
#           post.excerpt = rand(10) % 2 == 0 ? Forgery(:lorem_ipsum).words(10 + rand(50)) : nil
#           post.video_url = 'http://clips.vorwaerts-gmbh.de/VfE_html5.mp4'
#         end
#         if post.article?
#           post.excerpt = rand(10) % 2 == 0 ? Forgery(:lorem_ipsum).words(10 + rand(50)) : nil
#           post.image_public_id = rand % 2 == 0 ? 'MEN_it_s_time_to_up_ou_da_vinci_1_ssz21r' : nil
#           post.link_to_url = 'http://nautil.us/issue/41/selection/the-problem-with-modern-romance-is-too-much-choice'
#         end
#         post.share_text = post.default_share_text
#         post.share_link = 'https://magazine.ekcoffee.com'
#         post.save!
#       end

#       puts "seeded with 100 posts"
#     end

#     task :brews => :environment do
#       ActiveRecord::Base.connection.execute("TRUNCATE brews CASCADE") unless Rails.env.production?

#       50.times do
#         brew = Brew.new
#         brew.title = Forgery('lorem_ipsum').title
#         brew.notes = Forgery('lorem_ipsum').text
#         brew.happening_on = Date.today + ((2..7).to_a.sample).days
#         brew.starts_at = (9..21).to_a.sample
#         brew.primary_image_cloudinary_id = rand(10) % 2 == 0 ? '_MG_0580_uvtgbb' : nil
#         brew.place = Forgery('lorem_ipsum').title
#         brew.max_group_size = 8
#         brew.group_makeup = 0
#         brew.min_age = 21 + rand(20)
#         brew.max_age = brew.min_age + 5
#         brew.save!

#         brew.approve!

#         num_rsvp = rand(8)
#         brew.profiles = Profile.order("RANDOM()").limit(num_rsvp) if num_rsvp > 0
#        end

#        puts "seeded with 100 brews"
#     end
#   end
# end
