class AdminController < ApplicationController
  layout 'admin'

  before_action :load_admin_user, except: [:logout]
  before_action :admin_authenticated?, except: [:dashboard, :logout]
  before_action :load_metrics, if: lambda { @admin_user.present? }

  def dashboard
    session[:redirect_to] = '/dashboard'

    # metrics to track
    # m/f
    # dating/rel
    # age buckets
    # unmatch reasons
    # # of convos
    #
    #
    #

    @men = Profile.with_gender('male').count
    @women = Profile.with_gender('female').count
    @intent_dating = Profile.with_intent('Dating').count
    @intent_relationship = Profile.with_intent('Relationship').count
    @age_18_25 = Profile.age_gte(18).age_lte(25).count
    @age_26_30 = Profile.age_gte(26).age_lte(30).count
    @age_31_35 = Profile.age_gte(31).age_lte(35).count
    @age_35_40 = Profile.age_gte(35).age_lte(40).count
    @age_40_plus = Profile.age_gte(40).count
    @total = Profile.count
    @unmatched_reasons = Match::UNMATCH_REASONS.map { |k, v|  [v, Match.is_unmatched.with_unmatched_reason(v).count] }
  end

  def brew_dashboard
    @brews = Brew.ordered_by_recency
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

  def assign_desirability_score_user
    p = Profile.find params[:uuid]
    p.desirability_score = params[:score].to_f
    p.save!

    redirect_to :back
  end

  def moderate_user_stb
    p = Profile.find(params[:uuid])
    p.approved_for_stb = (params[:approved_for_stb] == 'true')
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
      props = { reviewed: true, approved: params[:approved] }
      props.merge!({ primary: false }) if !params[:approved]
      Photo.update(id, props)
      profile = photo.profile
      photo.destroy if !params[:approved]
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
    @new_butler_message_men_cnt = Profile.with_gender('male').with_needs_butler_attention(true).count
    @new_butler_message_women_cnt = Profile.with_gender('female').with_needs_butler_attention(true).count
    @profiles = Profile.with_needs_butler_attention(true).limit(25)
  end

  def show_butler_chat
    @profile = Profile.find params[:profile_uuid]
  end

  def update_butler_chat_flag
    Profile.update(params[:profile_uuid], needs_butler_attention: (params[:resolved] == 'false'))

    redirect_to :back
  end

  def send_butler_chat_notification
    PushNotifier.delay.record_event(params[:profile_uuid], 'new_butler_message', myname: params[:myname])
    Profile.update(params[:profile_uuid], has_new_butler_message: true)
    flash[:success] = 'Notification sent!'

    redirect_to :back
  end

  def logout
    reset_session

    redirect_to '/dashboard'
  end

  def destroy_user
    @profile = Profile.find(params[:uuid])
    if @profile.matched_with.detect { |m| m.active }.present? || @profile.matches.detect { |m| m.active }.present?
      flash[:error] = 'Cannot delete user who is in the middle of a conversation/mutually matched with someone'
      redirect_to :back
      return
    end

    Profile.find(params[:uuid]).destroy

    redirect_to :back
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
    @new_butler_chats_cnt = Profile.with_needs_butler_attention(true).count
    @profiles_cnt = Profile.count
    @unmoderated_cnt = Profile.with_moderation_status('unmoderated').order("created_at ASC").count
    @suspicious_cnt = Profile.with_moderation_status('unmoderated').possibly_not_single.count
    @unmoderated_photos_cnt = Photo.with_reviewed(false).count
    @profiles_marked_for_deletion_cnt = Profile.is_marked_for_deletion.count
  end
end
