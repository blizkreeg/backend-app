class FacebookAuthentication < SocialAuthentication
  def get_photo_albums_list(fields="id,name", limit=25, cursor=nil)
    graph_url = "#{self.oauth_uid}/albums?limit=#{limit}"
    graph_url += "&cursor=#{cursor}" if cursor.present?

    query_fb graph_url
  end

  def get_album_id_by_name(name)
    albums = get_photo_albums_list
    album = albums.detect { |album| album["name"] == name }
    while album.blank? && album["paging"]["next"].present?
      albums = get_photo_albums_list
      album = albums.select { |album| album["name"] == name }
    end

    album.present? ? album["id"] : nil
  rescue StandardError
    nil
  end

  def profile_pictures(fields="images,id", limit=8)
    album_id = get_album_id_by_name('Profile Pictures')
    if album_id
      photos_url = "#{album_id}/photos?limit=#{limit}&fields=#{fields}"
      photos = query_fb(photos_url)
      photos.inject([]) do |array, photo|
        # first element in 'images' of FB photo object seems to have the largest size
        largest_photo = photo["images"].first.clone
        hash = largest_photo.merge({
          "facebook_photo_id" => photo["id"]
        })
        array << hash
        array
      end
    else
      []
    end
  rescue StandardError => e
    EKC.logger.error "Error while accessing Facebook profile pictures uid: #{self.oauth_uid}"
    EKC.logger.error e.message
    []
  end

  def get_photo(photo_id)
    graph_url = "#{photo_id}"

    response_hash = query_fb graph_url
  end

  def get_photos_for_album(album_id, limit=50, fields='images,id')
    photos_url = "#{album_id}/photos?limit=#{limit}&fields=#{fields}"

    photos = query_fb(photos_url)
  end

  def mutual_friends_count(uid)
    graph_url = "#{uid}/?fields=context.fields(mutual_friends)"

    response_hash = query_fb graph_url
    if response_hash["context"].try(:[], "mutual_friends").present?
      response_hash["context"]["mutual_friends"].try(:[], "summary").try(:[], "total_count") || 0
    else
      0
    end
  rescue StandardError => e
    EKC.logger.error "Failed to get FB mutual friend count. Error: #{e.class.name}: #{e.message}"
    0
  end

  def total_friends_count
    graph_url = "me/friends"
    response_hash = query_fb graph_url
  end

  def query_fb(endpoint)
    fbgraph.get_object endpoint
  end

  private

  def fbgraph
    @graph ||= Koala::Facebook::API.new self.oauth_token, ENV['FACEBOOK_APP_SECRET']
  end
end
