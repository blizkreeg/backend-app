class AdminController < WebController
  layout 'admin'

  before_action :load_admin_user, except: [:logout]
  before_action :admin_authenticated?, except: [:dashboard, :logout]
  before_action :load_metrics, if: lambda { @admin_user.present? }
  before_action :show_bottom_menu, if: lambda { mobile_device? }

  def dashboard
    session[:redirect_to] = '/dashboard'

    @seen_yesterday = Profile.where("(properties->>'last_seen_at')::date = '#{(Time.now - 24.hours).utc.to_date.to_s}'::date").count
    @seen_today = Profile.where("(properties->>'last_seen_at')::date = '#{Time.now.utc.to_date.to_s}'::date").count
    @live_brews = Brew.live.count
    @for_review_brews = Brew.with_moderation_status('in_review').count
    @deleted_in_last_48h = Profile.where("(properties->>'marked_for_deletion_at')::date >= '#{(Time.now - 24.hours).utc.to_date.to_s}'::date").count
    @men = Profile.with_gender('male').count
    @women = Profile.with_gender('female').count

    @new_in_last_48h = Profile.where("(created_at)::date >= '#{(Time.now - 24.hours).utc.to_date.to_s}'::date").count
    @new_week_ago = Profile
                      .where("((created_at)::date >= '#{(Time.now - 8.days).utc.to_date.to_s}'::date) AND
                            ((created_at)::date <= '#{(Time.now - 7.days).utc.to_date.to_s}'::date)")
                      .count
    @deleted_week_ago = Profile
                        .where("((properties->>'marked_for_deletion_at')::date >= '#{(Time.now - 8.days).utc.to_date.to_s}'::date) AND
                            ((properties->>'marked_for_deletion_at')::date <= '#{(Time.now - 7.days).utc.to_date.to_s}'::date)")
                        .count

    @men_seen_in_last_1w = Profile
                            .with_gender('male')
                            .where("((properties->>'last_seen_at')::date >= '#{(Time.now - 7.days).utc.to_date.to_s}'::date) AND
                                    ((properties->>'last_seen_at')::date <= '#{Time.now.utc.to_date.to_s}'::date)")
                            .count
    @women_seen_in_last_1w = Profile
                              .with_gender('female')
                              .where("((properties->>'last_seen_at')::date >= '#{(Time.now - 7.days).utc.to_date.to_s}'::date) AND
                                      ((properties->>'last_seen_at')::date <= '#{Time.now.utc.to_date.to_s}'::date)")
                              .count
    @latest_brewings = Brewing.ordered_by_recency.limit(10)

    @usersthatmatter_yesterday = Profile.members.not_staff.where("(properties->>'last_seen_at')::date = '#{(Time.now - 24.hours).utc.to_date.to_s}'::date").count
    @usersthatmatter_today = Profile.members.not_staff.where("(properties->>'last_seen_at')::date = '#{Time.now.utc.to_date.to_s}'::date").count
    @usersthatmatter_total = Profile.members.not_staff.count
    @usersthatmatter_men = Profile.members.not_staff.with_gender('male').count
    @usersthatmatter_women = Profile.members.not_staff.with_gender('female').count

    # @intent_dating = Profile.with_intent('Dating').count
    # @intent_relationship = Profile.with_intent('Relationship').count
    # @age_18_25 = Profile.age_gte(18).age_lte(25).count
    # @age_26_30 = Profile.age_gte(26).age_lte(30).count
    # @age_31_35 = Profile.age_gte(31).age_lte(35).count
    # @age_35_40 = Profile.age_gte(35).age_lte(40).count
    # @age_40_plus = Profile.age_gte(40).count
    # @unmatched_reasons = Match::UNMATCH_REASONS.map { |k, v|  [v, Match.is_unmatched.with_unmatched_reason(v).count] }
    @total = Profile.count

    @page_title = 'Dashboard'
  end

  def search
    @profiles = Profile.where(nil)

    case params[:search][:type]
    when 'email'
      @profiles = @profiles.with_email(params[:search][:key])
    when 'firstname'
      @profiles = @profiles.with_firstname(params[:search][:key].capitalize)
    when 'lastname'
      @profiles = @profiles.with_lastname(params[:search][:key].capitalize)
    when 'fullname'
      first, last = params[:search][:key].split(' ')
      @profiles = @profiles.with_firstname(first.capitalize).with_lastname(last.capitalize)
    end

    @page_title = 'Users'

    render 'all_users'
  end

  def brew_dashboard
    ordered_brews = Brew.ordered_by_recency
    if params[:status]
      @brews = ordered_brews.with_moderation_status(params[:status])
    else
      @brews = ordered_brews.in_review + ordered_brews.live
    end

    @page_title = 'Brews'
  end

  def all_users
    @page = (params[:page] || 0).to_i

    if params[:approved] == '1'
      @profiles = Profile.members.not_staff.ordered_by_last_seen.offset(@page * 25).limit(25)
    else
      @profiles = Profile.ordered_by_last_seen.offset(@page * 25).limit(25)
    end

    @page_title = 'Users'
  end

  def unmoderated
    @unmoderated = to_be_moderated_profiles

    @page_title = 'To be Moderated (new) users'
  end

  def others
    @others = other_profiles

    @page_title = 'Other users'
  end

  def suspicious
    @suspicious_men_cnt = Profile.with_gender('male').with_moderation_status('unmoderated').possibly_not_single.count
    @suspicious_women_cnt = Profile.with_gender('female').with_moderation_status('unmoderated').possibly_not_single.count
    @suspicious = Profile.with_moderation_status('unmoderated').possibly_not_single.limit(25)

    @page_title = 'Suspicious users'
  end

  def profiles_marked_for_deletion
    # USE : Profile.is_marked_for_deletion.with_gender('male').group("properties->>'location_city'").select("count(uuid)")
    @profiles_marked_for_deletion = Profile.is_marked_for_deletion
  end

  def delete_profiles_marked_for_deletion
    profiles = params[:uuid].blank? ? Profile.is_marked_for_deletion : [Profile.find(params[:uuid])]
    num = profiles.size
    profiles.map(&:destroy)

    flash[:success] = "Successfully deleted #{num} profile(s)"
    redirect_to admin_profiles_marked_for_deletion_path
  end

  def lookup_user
    @profile = Profile.find(params[:uuid])
    redirect_to admin_show_user_path(@profile.uuid)
  end

  def show_user
    @profile = Profile.find params[:uuid]
  end

  def moderate_user
    p = Profile.find(params[:uuid])
    p.moderation_status = params[:moderation_status]
    p.visible = params[:moderation_status] == 'approved' ? true : false
    p.save!

    redirect_to :back
  end

  def assign_desirability_score_user
    notify_user = false
    p = Profile.find params[:uuid]
    if Ekc.launched_in?(p.latitude, p.longitude) && (params[:score].to_f > Profile::LOW_DESIRABILITY)
      p.moderation_status = 'approved'
      notify_user = true
    else
      p.moderation_status = 'flagged'
    end
    p.desirability_score = params[:score].to_f
    p.save!

    if notify_user
      # send email
      UserMailer.delay.welcome_email(p.uuid)

      # send push notification
      PushNotifier.delay.send_transactional_push([p.uuid],
                                                  'general_announcement',
                                                  body: "Woohoo #{p.firstname}! You're now part of the ekCoffee community. Welcome!")
    end

    redirect_to action: :unmoderated
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
    # affected_profiles.each do |uuid, profile|
    #   if !profile.blacklisted? # don't notify if profile was blacklisted
    #     PushNotifier.delay.record_event(uuid, 'profile_photo_rejected', myname: profile.firstname)
    #   end
    # end

    redirect_to :back
  end

  def new_butler_chats
    @new_butler_message_men_cnt = Profile.with_gender('male').with_needs_butler_attention(true).count
    @new_butler_message_women_cnt = Profile.with_gender('female').with_needs_butler_attention(true).count
    @profiles = Profile.with_needs_butler_attention(true).limit(25)
  end

  def show_butler_chat
    @profile = Profile.find params[:profile_uuid]

    @page_title = "Butler Chat"
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

  def approve_brew
    brew = Brew.find(params[:brew_id])
    brew.approve!

    NotificationsWorker.delay.notify_hosts_of_brew_approval(brew.id)

    redirect_to :back
  end

  def reject_brew
    brew = Brew.find(params[:brew_id])
    brew.reject!

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

    redirect_to admin_profiles_marked_for_deletion_path
  end

  def new_brew
    render 'admin/brews/new'
  end

  def create_brew
    @brew = Brew.create!(brew_params)

    redirect_to :brew_dashboard
  end

  def edit_brew
    @brew = Brew.find(params[:brew_id])

    render 'admin/brews/edit'
  end

  def update_brew
    @brew = Brew.find(params[:brew][:id])
    @brew.update!(brew_params)

    redirect_to :brew_dashboard
  end

  def content
    @posts = Post.ordered_by_recent
  end

  def create_content
    # post_in = (params[:post][:posted_on] || 0).to_i.hours
    params[:post][:posted_on] = Time.now.utc# + post_in
    post = Post.create!(post_params)
    notification_time = send_magazine_push(post).strftime("%-d %b @ %r %Z")

    flash[:success] = "Published magazine post! Push notification scheduled at #{notification_time}."
    redirect_to :back
  end

  def social_questions
    @social_questions = SocialQuestion.order("created_at DESC")
  end

  def activate_social_question
    @social_question = SocialQuestion.find(params[:social_question_id])
    @social_question.promote_to_active!

    flash[:success] = "Made question active!"
    redirect_to :back
  end

  def create_social_question
    SocialQuestion.create!(social_question_params)

    flash[:success] = "Created question!"
    redirect_to :back
  end

  def update_profile
    profile = Profile.find(params[:uuid])

    # expects jsonified hash of properties in params[:properties]
    profile.update!(JSON.parse(params[:properties]))

    flash[:success] = "profile updated!"
    redirect_to :back
  end

  private

  def brew_params
    params.require(:brew).permit(:title,
                                  :notes,
                                  :happening_on,
                                  :starts_at,
                                  :place,
                                  :address,
                                  :min_age,
                                  :max_age,
                                  :hosted_by_ekcoffee,
                                  :primary_image_cloudinary_id)
  end

  def post_params
    params.require(:post).permit(:title,
                                  :post_type,
                                  :posted_on,
                                  :excerpt,
                                  :image_public_id,
                                  :video_url,
                                  :link_to_url)
  end

  def social_question_params
    params.require(:social_question).permit(:question_text, :question_lede)
  end

  def load_admin_user
    if params[:login_with].present?
      token = JWT.decode(params[:login_with], Rails.application.secrets.secret_key_base).try(:first)
      if token
        seconds_since_token = Time.now.to_i - token['created_at'].to_i
        if seconds_since_token <= token['valid_for'].to_i
          @current_profile = Profile.find(token['uuid'])
          session[:profile_uuid] = @current_profile.uuid
        else
          raise "Login token is invalid"
        end
      end
    end

    if current_profile_is_admin?
      @admin_user = @current_profile
    else
      @admin_user = Profile.find(session[:profile_uuid]) if session[:profile_uuid].present?
    end
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
    @suspicious_cnt = Profile.with_moderation_status('unmoderated').possibly_not_single.count
    @unmoderated_photos_cnt = Photo.with_reviewed(false).count
    @profiles_marked_for_deletion_cnt = Profile.is_marked_for_deletion.count
  end

  def send_magazine_push(post)
    # send push notification at 6pm
    now_ist = Time.now.utc.in_time_zone('Kolkata')
    send_to_uuids = Profile.members.pluck(:uuid)
    if now_ist.hour <= 18
      send_at = now_ist.change(hour: 18)
    else
      send_at = now_ist.change(hour: 18, day: (now_ist.day+1))
    end
    PushNotifier.delay_until(send_at).send_transactional_push(send_to_uuids,
                                                              'new_content',
                                                              body: "On the Magazine now: #{post.title}")

    send_at
  end

  def to_be_moderated_profiles
    @tbm ||= Profile.with_moderation_status('unmoderated').order("created_at DESC").select { |p| Ekc.launched_in?(p.latitude, p.longitude) }
  end

  def other_profiles
    @others ||= Profile.with_moderation_status('unmoderated').order("created_at DESC").select { |p| p.latitude.nil? || p.longitude.nil? || !Ekc.launched_in?(p.latitude, p.longitude) }
  end

  def show_bottom_menu
    @show_bottom_menu = true
  end
end
