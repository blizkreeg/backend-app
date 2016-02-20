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

  def update_state
    profile = Profile.find(params[:uuid])
    profile.update! state: params[:state], state_endpoint: nil

    if params[:state] == 'waiting_for_matches'
      profile.matches.mutual_like.each do |match|
        p = match.matched_profile
        p.state = 'waiting_for_matches'
        p.save!

        match.conversation.messages.map(&:destroy)
      end
    end

    redirect_to :back
  end

  def create_mutual_match
    profile = Profile.find params[:for_profile_uuid]

    if profile.matches.liked.count > 0
      @match = profile.matches.liked.take!
      r_match = @match.reverse
      r_match.update!(decision: 'Like') if r_match.undecided?

      Match.mark_if_mutual_like([@match.id])
    else
      # TBD implement matching logic
      opposite_gender = profile.male? ? 'female' : 'male'
      matched_profile = Profile.with_gender(opposite_gender).take!

      @match, r_match = Matchmaker.create_between(profile, matched_profile)
      Matchmaker.create_conversation([profile.uuid, matched_profile.uuid])

      @match.update! decision: 'Like'
      r_match.update! decision: 'Like'

      Match.mark_if_mutual_like([@match.id])
    end

    profile.got_mutual_like!(:mutual_match, v1_profile_match_path(profile.uuid, @match.id))

    if profile.male?
      t = @match.matched_profile
      t.state = 'mutual_match'
      t.save!
    else
      c = @match.conversation
      c.append_message!('test mesasge from guy', @match.matched_profile.uuid)
      c.save!

      t = @match.matched_profile
      t.state = 'waiting_for_matches_and_response'
      t.save!
    end

    redirect_to :back
  end
end
