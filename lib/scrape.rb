require 'openssl'
require 'httparty'
require 'nokogiri'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

module Scrape
  module_function

  def run(city_name, type)
    type_of_place =
    case type
    when 'cafes'
      'Coffee'
    end
    page_url = "https://www.zomato.com/#{city_name.downcase}/restaurants/#{type}"

    parsed = Nokogiri::HTML(HTTParty.get(page_url))
    parsed.css('ol#orig-search-list').css('li.js-search-result-li').first(10).map do |lineitem|
      img_url = lineitem.css('.search-result').css('.search_left_featured').css('a').attribute('data-original').value
      name = ActiveSupport::Inflector.transliterate lineitem.css('.search-result').css('.top-res-box-name').css('.result-title').text
      street_address = lineitem.css('.search-result').css('.search-result-address').text
      city = city_name.camelcase

      puts "looking up #{name}"

      gplaces_result = HTTParty.get "https://maps.googleapis.com/maps/api/place/nearbysearch/json?key=#{ENV['GOOGLE_PLACES_API_KEY']}&location=18.98,72.83&radius=10000&name=#{name}", verify_ssl: false
      puts "found #{gplaces_result['results'].size}"
      if gplaces_result['results'].present?
        xid = SecureRandom.hex(Photo::PUBLIC_ID_LENGTH)
        uploaded_hash = Cloudinary::Uploader.upload(img_url,
                                                    public_id: xid,
                                                    transformation: { width: Photo::MAX_WIDTH, height: Photo::MAX_HEIGHT, crop: :limit },
                                                    tags: [Rails.env],
                                                    verify_ssl: false)

        gplaces_result['results'].each do |t|
          puts "getting details on place id #{t['place_id']}"
          place = HTTParty.get "https://maps.googleapis.com/maps/api/place/details/json?key=#{ENV['GOOGLE_PLACES_API_KEY']}&placeid=#{t['place_id']}", verify_ssl: false

          if place['result'].present?
            puts "...found!"
            result = place['result']
            addrs = result['address_components']

            DatePlace.create!(
              name: result['name'],
              street_address: result['vicinity'],
              city: addrs.select { |addr| addr['types'].include?('locality') }.first.try(:[], 'long_name'),
              part_of_city: addrs.select { |addr| addr['types'].include?('sublocality_level_1') }.first.try(:[], 'long_name') ||
                            addrs.select { |addr| addr['types'].include?('sublocality_level_2') }.first.try(:[], 'long_name') ||
                            addrs.select { |addr| addr['types'].include?('sublocality_level_3') }.first.try(:[], 'long_name'),
              state: addrs.select { |addr| addr['types'].include?('administrative_area_level_1') }.first.try(:[], 'long_name'),
              country: addrs.select { |addr| addr['types'].include?('country') }.first.try(:[], 'long_name'),
              latitude: result['geometry']['location']['lat'],
              longitude: result['geometry']['location']['lng'],
              date_types: [type_of_place],
              photos_public_ids: [uploaded_hash["public_id"]]
            )
          end
        end
      end
    end
  end
end
