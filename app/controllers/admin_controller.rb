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
    params[:approved] = (params[:approved] == 'true')
    params[:ids].each do |id|
      if !params[:approved]
        photo = Photo.find(id)
        rejected_photo_was_primary = photo.primary
      end
      props = { reviewed: true, approved: params[:approved] }
      props.merge!({ primary: false }) if !params[:approved]
      Photo.update(id, props)
      photo.profile.test_and_set_primary_photo! if rejected_photo_was_primary
    end

    # here a butler chat should be sent to user

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
end
