class AdminController < ApplicationController
  layout 'admin'

  before_action :load_admin_user
  before_action :admin_authenticated?, except: [:dashboard, :logout]

  def dashboard
    if @admin_user.present?
      @new_butler_chats_cnt = Profile.with_has_new_butler_message(true).count
    end

    session[:redirect_to] = '/dashboard'
  end

  def unmoderated
    @unmoderated_men_cnt = Profile.with_gender('male').with_moderation_status('unmoderated').count
    @unmoderated_women_cnt = Profile.with_gender('female').with_moderation_status('unmoderated').count
    @unmoderated = Profile.with_moderation_status('unmoderated').order("created_at ASC").limit(25)
  end

  def suspicious
    @suspicious_men_cnt = Profile.with_gender('male').with_moderation_status('unmoderated').with_possible_relationship_status('Married').count
    @suspicious_women_cnt = Profile.with_gender('female').with_moderation_status('unmoderated').with_possible_relationship_status('Married').count
    @suspicious = Profile.with_moderation_status('unmoderated').with_possible_relationship_status('Married').limit(25)
  end

  def lookup_user
    @profile = Profile.find(params[:uuid])
    redirect_to admin_show_user_path(@profile.uuid)
  end

  def show_user
    @profile = Profile.find params[:uuid]
  end

  def moderate_user
    puts params[:uuid]

    redirect_to :back
  end

  def review_photos
    @unmoderated_photos_cnt = Photo.with_reviewed(false).count
    @unmoderated_photos = Photo.with_reviewed(false).order("created_at DESC").limit(25)
  end

  def moderate_photos
    params[:ids].each do |id|
      Photo.update(id, reviewed: true, approved: params[:approved])
    end

    # here a butler chat should be sent to user

    redirect_to :back
  end

  def logout
    reset_session

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
end
