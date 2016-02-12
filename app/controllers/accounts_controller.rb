# TBD - DISABLE BEFORE GOING TO PROD!!
class AccountsController < ApplicationController
  skip_before_action :verify_authenticity_token

  layout 'application'

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
    @profile = Profile.find(session[:profile_uuid])
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
    profile.update! state: params[:state]
    redirect_to :back
  end
end
