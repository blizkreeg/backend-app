# TBD - DISABLE BEFORE GOING TO PROD!!

class AccountsController < ApplicationController
  skip_before_action :verify_authenticity_token

  layout 'application'

  include Matchmaker

  def login
  end

  def callback
    uid = request.env["omniauth.auth"]["uid"]
    puts uid, request.env["omniauth.auth"]["credentials"].inspect
    fb = FacebookAuthentication.where(oauth_uid: uid).take!
    profile = fb.profile

    session[:profile_uuid] = profile.uuid

    redirect_to :show
  rescue ActiveRecord::RecordNotFound
    render text: 'Profile not found!'
  end

  def show
    uuid = params[:profile_uuid] || session[:profile_uuid]

    @profile = Profile.find(uuid)
  end

  def destroy
    profile = Profile.find(params[:uuid])
    profile.destroy

    redirect_to :login
  rescue ActiveRecord::RecordNotFound
    flash[:error] = 'Profile not found!'
    redirect_to :back
  end

  def index
    @profiles = Profile.all.order('updated_at DESC')
  end

  def reset_state
    profile = Profile.find(params[:uuid])
    profile.update! state: params[:state], state_endpoint: nil

    if profile.active_mutual_match
      match = profile.active_mutual_match
      p = match.matched_profile
      p.state = 'waiting_for_matches'
      p.save!

      if match.conversation
        match.conversation.messages.map(&:destroy)
        match.conversation.destroy
      end

      match.reverse.destroy
      match.destroy
    end

    profile.reload

    profile.matches.each do |match|
      if match.conversation
        match.conversation.messages.map(&:destroy)
        match.conversation.destroy
      end

      match.reverse.destroy
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
      @match = profile.matches.liked.take!
      r_match = @match.reverse
      r_match.update!(decision: 'Like') if r_match.undecided?

      Match.enable_mutual_flag_and_create_conversation!([@match.id])

      profile.set_next_active!
    else
      # TBD implement matching logic
      opposite_gender = profile.male? ? 'female' : 'male'
      matched_profile = Profile.with_gender(opposite_gender).take!
      matched_profile.state = 'waiting_for_matches'
      matched_profile.save!

      @match, r_match = Matchmaker.create_between(profile, matched_profile)

      Matchmaker.create_conversation([profile.uuid, matched_profile.uuid])

      @match.update! decision: 'Like'
      r_match.update! decision: 'Like'

      Match.enable_mutual_flag_and_create_conversation!([@match.id])

      profile.set_next_active!
    end

    if profile.female?
      c = @match.conversation
      c.append_message!('test message from guy', @match.matched_profile.uuid)
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
end
