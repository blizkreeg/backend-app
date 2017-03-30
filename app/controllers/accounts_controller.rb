# TBD - DISABLE BEFORE GOING TO PROD!!

class AccountsController < ApplicationController
  skip_before_action :verify_authenticity_token

  layout 'application'

  include Matchmaker

  before_action :set_account_profile, except: [:login, :callback]

  def login
    session[:redirect_to] = '/show'
  end

  def callback
    uid = request.env["omniauth.auth"]["uid"]
    puts uid, request.env["omniauth.auth"]["credentials"].inspect

    if !ADMIN_FB_OAUTH_UIDS.include?(uid)
      flash[:error] = "Can't find what you're looking for..."
      redirect_to session[:redirect_to]
      return
    end

    fb = FacebookAuthentication.where(oauth_uid: uid).take!
    new_token = request.env["omniauth.auth"]["credentials"]["token"]
    new_expires_at = request.env["omniauth.auth"]["credentials"]["expires_at"]
    fb.update! oauth_token: new_token, oauth_token_expiration: new_expires_at, oauth_hash: request.env["omniauth.auth"]

    profile = fb.profile

    session[:profile_uuid] = profile.uuid

    redirect_to session[:redirect_to]
  rescue ActiveRecord::RecordNotFound
    render text: 'Profile not found!'
  end

  def admin
  end

  def show
  end

  def test_flow

  end

  def update_test_flow
    state = params[:state] # update to this state

    case state
    when 'waiting_for_matches'
      @profile.update!(state: state, state_endpoint: nil, substate: nil, substate_endpoint: nil)

      if @profile.active_mutual_match
        match = @profile.active_mutual_match
        match.matched_profile.update! state: state

        if match.conversation
          match.conversation.messages.map(&:destroy)
          match.conversation.destroy
        end

        match.reverse.destroy rescue nil
        match.destroy
      end

      @profile.reload

      @profile.matches.each do |match|
        if match.conversation
          match.conversation.messages.map(&:destroy)
          match.conversation.destroy
        end

        match.reverse.destroy rescue nil
        match.destroy
      end
    when 'has_matches'
      matched_profiles = Profile.of_gender(@profile.seeking_gender).limit(3)
      matched_profiles.each do |matched_profile|
        Matchmaker.create_matches_between(@profile.uuid, matched_profile.uuid,
                                    normalized_distance: 0,
                                    friends_with: false,
                                    num_common_friends: rand(3))
      end
      @profile.new_matches!(:has_matches, Rails.application.routes.url_helpers.v1_profile_matches_path(@profile))
    when 'show_matches'
    when 'in_conversation'
      match = @profile.matches.take
      match.update! decision: 'Like'
      match.reverse.update! decision: 'Like'
      Match.enable_mutual_flag_and_create_conversation!([match.id, match.reverse.id])
      match.active!
      match.reverse.active!
      match.conversation.open!
      # case substate
      # when 'info'
      # when 'ready_to_meet'
      # when 'health_check'
      # when 'show_date_suggestions'
      # when 'radio_silence'
      # when 'check_if_meeting'
      # when 'close_notice'
      # end
    end

    redirect_to :back
  end

  def create_matches
    Matchmaker.generate_new_matches_for(@profile.uuid)
    @profile.reload
    @profile.new_matches!(:has_matches) if @profile.has_queued_matches?

    redirect_to :back
  end

  def check_mutual_match
    if @profile.waiting_for_matches?
      Matchmaker.transition_to_mutual_match(@profile.uuid, @profile.matches.mutual.detect { |match| match.matched_profile.waiting_for_matches? }.id)
    end
  end

  def move_conversation
    Conversation.move_conversation_to(@profile.active_mutual_match.conversation.id, params[:conv_state])
    flash[:success] = "Done"
    redirect_to :back
  end

  def show_butler_chat
    uuid = params[:profile_uuid] || session[:profile_uuid]

    @profile = Profile.find(uuid)
  end

  def destroy
    profile = Profile.find(params[:uuid])
    profile.destroy!

    redirect_to :login
  rescue ActiveRecord::RecordNotFound
    flash[:error] = 'Profile not found!'
    redirect_to :back
  end

  def index
    @profiles = Profile.all.order('updated_at DESC').limit(50)
  end

  def reset_state
    profile = Profile.find(params[:uuid])
    profile.update!(state: params[:state], state_endpoint: nil, substate: nil, substate_endpoint: nil)

    if profile.active_mutual_match
      match = profile.active_mutual_match
      p = match.matched_profile
      p.state = 'waiting_for_matches'
      p.save!

      if match.conversation
        match.conversation.messages.map(&:destroy)
        match.conversation.destroy
      end

      match.reverse.destroy rescue nil
      match.destroy
    end

    profile.reload

    profile.matches.each do |match|
      if match.conversation
        match.conversation.messages.map(&:destroy)
        match.conversation.destroy
      end

      match.reverse.destroy rescue nil
      match.destroy
    end

    redirect_to :back
  end

  def reverse_gender
    profile = Profile.find(params[:uuid])
    if profile.male?
      profile.gender = 'female'
    else
      profile.gender = 'male'
    end
    profile.save!

    redirect_to :back
  end

  def create_mutual_match
    profile = Profile.find params[:for_profile_uuid]
    profile.state = 'waiting_for_matches'
    profile.save!

    if profile.active_mutual_match
      @match = profile.active_mutual_match
    elsif profile.matches.liked.count > 0
      @match = profile.matches.liked.select { |m| m.matched_profile.active_mutual_match.blank? }.first
      r_match = @match.reverse
      r_match.update!(decision: 'Like') if r_match.undecided?

      Match.enable_mutual_flag_and_create_conversation!([@match.id])

      profile.set_next_active!
    else
      # TBD implement matching logic
      opposite_gender = profile.male? ? 'female' : 'male'
      matched_profile = Profile.with_gender(opposite_gender).limit(25).select { |p| p.active_mutual_match.blank? }.first
      matched_profile.state = 'waiting_for_matches'
      matched_profile.save!

      @match, r_match = Matchmaker.create_matches_between(profile, matched_profile)

      Matchmaker.create_conversation([profile.uuid, matched_profile.uuid])

      @match.update! decision: 'Like'
      r_match.update! decision: 'Like'

      Match.enable_mutual_flag_and_create_conversation!([@match.id])

      profile.set_next_active!
    end

    if profile.female?
      c = @match.conversation
      c.add_message!('test message from guy', @match.matched_profile.uuid, Message::TYPE_CHAT)
      c.save!

      t = @match.matched_profile
      t.state = 'waiting_for_matches_and_response'
      t.save!
    end

    profile.got_mutual_like!(:mutual_match, v1_profile_match_path(profile.uuid, @match.id))

    redirect_to :back
  end

  def start_conversation
    match = Match.find params[:match_id]

    p1 = match.for_profile
    p2 = match.matched_profile

    p1.state = 'in_conversation'
    p1.save!

    p2.state = 'in_conversation'
    p2.save!

    redirect_to :back
  end

  def update_conversation_state
    conv = Conversation.find(params[:conv_id])
    conv.state = params[:conv_state]
    conv.save!

    redirect_to :back
  end

  def switch_to_post_date_feedback
    @profile = Profile.find(params[:uuid])

    if @profile.real_dates.blank?
      if @profile.matches.blank?
        opposite_gender = @profile.male? ? 'female' : 'male'
        matched_profiles = Profile.with_gender(opposite_gender).limit(1).reorder("RANDOM()")
        matched_profiles.map { |matched_profile|
                              male_uuid = @profile.male? ? @profile.uuid : matched_profile.uuid;
                              Match.create_with(delivered_at: DateTime.now,
                                                expires_at: DateTime.now + Match::STALE_EXPIRATION_DURATION,
                                                initiates_profile_uuid: male_uuid)
                              .find_or_create_by(for_profile_uuid: @profile.uuid, matched_profile_uuid: matched_profile.uuid) }
        @profile.reload
      end
      if @profile.matches.map(&:conversation).compact.blank?
        Matchmaker.create_conversation([@profile.uuid, @profile.matches.first.matched_profile.uuid])
        @profile.reload
      end

      a_conversation = @profile.matches.map { |m| m.conversation }.first
      RealDate.find_or_create_by(profile_uuid: @profile.uuid, conversation_id: a_conversation.id) if a_conversation.present?
      @profile.reload
    end

    @profile.substate = 'post_date_feedback'
    @profile.substate_endpoint = v1_profile_real_date_path(@profile.uuid, @profile.real_dates.first.id)

    @profile.save!

    redirect_to :back
  end

  def send_push_notification
    @profile = Profile.find(params[:uuid])

    PushNotifier.record_event(params[:uuid], params[:notification_type], myname: @profile.firstname, name: @profile.active_mutual_match.try(:matched_profile).try(:firstname))

    flash[:message] = "Sent Push Notification!"

    redirect_to :back
  end

  private

  def set_account_profile
    uuid = params[:profile_uuid] || session[:profile_uuid]
    @profile = Profile.find(uuid)

    redirect_to action: :login if @profile.blank?
  end
end
