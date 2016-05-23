class AdminController < ApplicationController
  layout 'admin'

  before_action :load_admin_user

  def dashboard
    @new_butler_chats_cnt = Profile.with_has_new_butler_message(true).count
  end

  def unmoderated
    @unmoderated_men_cnt = Profile.with_gender('male').with_moderation_status('unmoderated').count
    @unmoderated_women_cnt = Profile.with_gender('female').with_moderation_status('unmoderated').count
    @unmoderated = Profile.with_moderation_status('unmoderated').limit(25)
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

    # here something should be sent to user

    redirect_to :back
  end

  private

  def load_admin_user
    # @admin_user = Profile.find(session[:user_uuid]) if session[:user_uuid].present?
    @admin_user = Profile.with_email('vinthanedar@gmail.com').take
  end
end
