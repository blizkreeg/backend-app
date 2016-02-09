# TBD - DISABLE BEFORE GOING TO PROD!!
class AccountsController < ApplicationController
  def login
  end

  def show
    uid = request.env["omniauth.auth"]["uid"]
    puts uid, request.env["omniauth.auth"]["credentials"].inspect
    fb = FacebookAuthentication.where(oauth_uid: uid).take!
    @profile = fb.profile
  rescue ActiveRecord::RecordNotFound
    render text: 'Profile not found!'
  end

  def destroy
    profile = Profile.find(params[:uuid])
    profile.destroy

    redirect_to :login
  rescue ActiveRecord::RecordNotFound
    flash[:error] = 'Profile not found!'
    redirect_to :back
  end
end
