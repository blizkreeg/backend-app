class Api::V1::PhotosController < ApplicationController
  respond_to :json

  before_action :authenticated?
  before_action :validate_json_schema, except: [:create]
  before_action except: [] do
    authorized?(params[:profile_uuid])
  end

  def create
    # file upload
    if params[:photo_file].present?
      uploaded_hash = Cloudinary::Uploader.upload(params[:photo_file], public_id: SecureRandom.hex(Photo::PUBLIC_ID_LENGTH))

      @current_profile.photos << Photo.new(public_id: uploaded_hash['public_id'],
                                            public_version: uploaded_hash['public_version'],
                                            original_width: uploaded_hash['width'],
                                            original_height: uploaded_hash['height'],
                                            original_url: uploaded_hash['url'])
      @current_profile.save!
    else
      # add photo from FB album
      fb_photo_hash = @current_profile.facebook_authentication.get_photo(params[:data][:facebook_photo_id])
      if fb_photo_hash.present?
        fb_photo_url = fb_photo_hash['images'].first['source']
        uploaded_hash = Photo.upload_remote_photo_to_cloudinary(fb_photo_url)
        @current_profile.photos << Photo.new(public_id: uploaded_hash['public_id'],
                                            public_version: uploaded_hash['public_version'],
                                            original_width: uploaded_hash['width'],
                                            original_height: uploaded_hash['height'],
                                            original_url: uploaded_hash['url'],
                                            facebook_id: params[:data][:facebook_photo_id])
        @current_profile.save!
      end
    end

    @current_profile.test_and_set_primary_photo!

    @photos = @current_profile.photos.ordered

    render 'api/v1/photos/index', status: 200
  end

  def index
    @photos = @current_profile.photos.ordered

    render status: 200
  end

  def show
  end

  def update
    photo = Photo.find(params[:id])
    photo.update!(photo_params)

    @current_profile.test_and_set_primary_photo!

    @photos = @current_profile.photos.ordered

    render 'api/v1/photos/index', status: 200
  end

  def destroy
    photo = Photo.find(params[:id])

    raise Errors::OperationNotPermitted, "Photo not owned by user" if photo.profile.uuid != @current_profile.uuid

    photo.destroy

    @current_profile.test_and_set_primary_photo!

    @photos = @current_profile.photos

    render 'api/v1/photos/index', status: 200
  end

  def show_facebook_albums
    @facebook_albums = @current_profile.facebook_authentication.get_photo_albums_list

    render status: 200
  end

  def show_facebook_album_photos
    @album_photos = @current_profile.facebook_authentication.get_photos_for_album(params[:album_id])

    render status: 200
  end

  private

  def photo_params
    params.require(:data).permit(*Photo::MASS_UPDATE_ATTRIBUTES)
  end
end
