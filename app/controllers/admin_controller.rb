class AdminController < ApplicationController
  layout 'admin'

  before_action :load_admin_user, except: [:logout]
  before_action :admin_authenticated?, except: [:dashboard, :logout]
  before_action :load_metrics, if: lambda { @admin_user.present? }

  def dashboard
    session[:redirect_to] = '/dashboard'
  end

  def all_users
    @page = (params[:page] || 0).to_i
    @profiles = Profile.order("created_at DESC").offset(@page * 25).limit(25)
  end

  def unmoderated
    @unmoderated_men_cnt = Profile.with_gender('male').with_moderation_status('unmoderated').count
    @unmoderated_women_cnt = Profile.with_gender('female').with_moderation_status('unmoderated').count
    @unmoderated = Profile.with_moderation_status('unmoderated').order("created_at ASC").limit(25)
  end

  def suspicious
    @suspicious_men_cnt = Profile.with_gender('male').with_moderation_status('unmoderated').possibly_not_single.count
    @suspicious_women_cnt = Profile.with_gender('female').with_moderation_status('unmoderated').possibly_not_single.count
    @suspicious = Profile.with_moderation_status('unmoderated').possibly_not_single.limit(25)
  end

  def profiles_marked_for_deletion
    @profiles_marked_for_deletion_m = Profile.is_marked_for_deletion.with_gender('male')
    @profiles_marked_for_deletion_w = Profile.is_marked_for_deletion.with_gender('female')
  end

  def lookup_user
    @profile = Profile.find(params[:uuid])
    redirect_to admin_show_user_path(@profile.uuid)
  end

  def show_user
    @profile = Profile.find params[:uuid]
  end

  def moderate_user
    p = Profile.find params[:uuid]
    p.moderation_status = params[:moderation_status]
    p.visible = params[:moderation_status] == 'approved' ? true : false
    p.save!

    redirect_to :back
  end

  def review_photos
    @unmoderated_photos_cnt = Photo.with_reviewed(false).count
    @unmoderated_photos = Photo.with_reviewed(false).order("created_at DESC").limit(25)
  end

  def moderate_photos
    affected_profiles = {}
    params[:approved] = (params[:approved] == 'true')
    params[:ids].each do |id|
      photo = Photo.find(id)
      if !params[:approved]
        rejected_photo_was_primary = photo.primary
      end
      # TBD: later when we move to rejecting photo and then giving user option to delete
      # uncomment this
      # props = { reviewed: true, approved: params[:approved] }
      # props.merge!({ primary: false }) if !params[:approved]
      # Photo.update(id, props)
      profile = photo.profile
      photo.destroy
      profile.test_and_set_primary_photo! if rejected_photo_was_primary
      unless params[:approved]
        if profile.photos.approved.count == 0
          if !profile.blacklisted? # if blacklisted, don't do anything
            profile.update!(visible: false, moderation_status: 'flagged', moderation_status_reason: Profile::MODERATION_STATUS_REASONS[:nophotos])
          end
        end
        affected_profiles[profile.uuid] = profile
      end
    end

    # here a butler chat should be sent to user
    affected_profiles.each do |uuid, profile|
      if !profile.blacklisted? # don't notify if profile was blacklisted
        PushNotifier.delay.record_event(uuid, 'profile_photo_rejected', myname: profile.firstname)
      end
    end

    redirect_to :back
  end

  def new_butler_chats
    @new_butler_message_men_cnt = Profile.with_gender('male').with_has_new_butler_message(true).count
    @new_butler_message_women_cnt = Profile.with_gender('female').with_has_new_butler_message(true).count
    @profiles = Profile.with_has_new_butler_message(true).limit(25)
  end

  def show_butler_chat
    @profile = Profile.find params[:profile_uuid]
  end

  def update_butler_chat_flag
    Profile.update(params[:profile_uuid], has_new_butler_message: (params[:resolved] == 'false'))

    redirect_to :back
  end

  def send_butler_chat_notification
    PushNotifier.delay.record_event(params[:profile_uuid], 'new_butler_message', myname: params[:myname])
    flash[:success] = 'Notification sent!'

    redirect_to :back
  end

  def logout
    reset_session

    redirect_to '/dashboard'
  end

  private

  def load_admin_user
    @admin_user = Profile.find(session[:profile_uuid]) if session[:profile_uuid].present?
  end

  def admin_authenticated?
    if @admin_user.blank?
      flash[:error] = 'You need to be logged in!'
      redirect_to action: 'dashboard'
    end
  end

  def load_metrics
    @new_butler_chats_cnt = Profile.with_has_new_butler_message(true).count
    @profiles_cnt = Profile.count
    @unmoderated_cnt = Profile.with_moderation_status('unmoderated').order("created_at ASC").count
    @suspicious_cnt = Profile.with_moderation_status('unmoderated').possibly_not_single.count
    @unmoderated_photos_cnt = Photo.with_reviewed(false).count
    @profiles_marked_for_deletion_cnt = Profile.is_marked_for_deletion.count
  end
end
