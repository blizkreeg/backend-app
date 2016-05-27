# TBD: make sure all FB error responses are handled: https://developers.facebook.com/docs/graph-api/using-graph-api
class FacebookAuthentication < SocialAuthentication
  MANDATORY_FACEBOOK_PERMISSIONS = %w(email public_profile user_photos user_birthday)
  NUM_PROFILE_PICTURES_TO_GET = 6

  def get_photo_albums_list(fields="id,name", limit=25, cursor=nil)
    key = ['fb_albums', self.oauth_uid, fields.downcase.gsub(/[^\w]/i, '_'), limit.to_s].join('_')
    Rails.cache.fetch(key, expires_in: 14.days) do
      graph_url = "#{self.oauth_uid}/albums?limit=#{limit}"
      graph_url += "&cursor=#{cursor}" if cursor.present?

      response_hash = query_fb(graph_url)
      # removes comments and likes nodes from each album node since they bloat the payload
      response_hash = response_hash.map { |album_hash|
                        album_hash = album_hash.except("comments")
                        album_hash = album_hash.except("likes")
                        album_hash
                      }
    end
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

  def profile_pictures(fields="images,id", limit=NUM_PROFILE_PICTURES_TO_GET)
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
    key = ['fb_photo', self.oauth_uid, photo_id].join('_')
    Rails.cache.fetch(key, expires_in: 14.days) do
      graph_url = "#{photo_id}"

      response_hash = query_fb(graph_url)
      # removes comments and likes nodes from the response since they bloat the payload
      response_hash = response_hash.except("comments") if response_hash.present?
      response_hash = response_hash.except("likes") if response_hash.present?

      response_hash
    end
  end

  def get_photos_for_album(album_id, fields='images,id', limit=50)
    key = ['fb_album_photos', self.oauth_uid, album_id, fields.downcase.gsub(/[^\w]/i, '_'), limit.to_s].join('_')
    Rails.cache.fetch(key, expires_in: 14.days) do
      photos_url = "#{album_id}/photos?limit=#{limit}&fields=#{fields}"

      query_fb(photos_url)
    end
  end

  def granted_permissions
    graph_url = "#{self.oauth_uid}/permissions"
    response_hash = query_fb(graph_url)
    response_hash.map { |permission| permission["permission"] if permission["status"] == "granted" }.compact
  end

  def declined_permissions
    graph_url = "#{self.oauth_uid}/permissions"
    response_hash = query_fb(graph_url)
    response_hash.map { |permission| permission["permission"] if permission["status"] == "declined" }.compact
  end

  def friends_with?(uid)
    graph_url = "#{self.oauth_uid}/friends/#{uid}"
    response_hash = query_fb(graph_url)

    response_hash.present? && response_hash.is_a?(Array) && response_hash.detect { |user| user["id"] == uid }.present?
  end

  def mutual_friends_count(uid)
    graph_url = "#{uid}/?fields=context.fields(mutual_friends)"

    response_hash = query_fb(graph_url)
    if response_hash["context"].try(:[], "mutual_friends").present?
      response_hash["context"]["mutual_friends"].try(:[], "summary").try(:[], "total_count") || 0
    else
      0
    end
  rescue StandardError => e
    EKC.logger.error "Failed to get FB mutual friend count. Error: #{e.class.name}: #{e.message}"
    0
  end

  def query_fb(endpoint)
    check_facebook_permissions! unless @checking_permissions

    @checking_permissions = false
    @first_try = true

    begin
      fbgraph.get_object endpoint
    rescue Koala::Facebook::AuthenticationError => e
      log_fb_error(e)
      raise Errors::FacebookAuthenticationError, "Your Facebook session needs to be refreshed. Please login again to continue."
    rescue Koala::Facebook::ClientError => e
    rescue Koala::Facebook::ServerError => e
    rescue Koala::Facebook::BadFacebookResponse => e
      if @first_try
        @first_try = false
        retry
      end
      log_fb_error(e)
      raise Errors::FacebookAuthenticationError, "There was a problem accessing your Facebook account. Please login again to continue."
    end
  end

  private

  def fbgraph
    @graph ||= Koala::Facebook::API.new self.oauth_token, ENV['FACEBOOK_APP_SECRET']
  end

  def log_fb_error(e)
    EKC.logger.error "ERROR: Facebook exception! profile-uuid: #{self.profile.uuid}, type: #{e.fb_error_type}, code: #{e.fb_error_code}, error_subcode: #{e.fb_error_subcode}, message: #{e.fb_error_message}"
  end

  def check_facebook_permissions!
    @checking_permissions = true

    declined_required_perms = self.declined_permissions & MANDATORY_FACEBOOK_PERMISSIONS

    if declined_required_perms.present?
      raise Errors::FacebookPermissionsError, "We require the '#{declined_required_perms.join(', ')}' #{declined_required_perms.size > 1 ? 'permissions' : 'permission'} from your Facebook to verify authenticity of your profile. Please login again to continue."
    end
  end
end
