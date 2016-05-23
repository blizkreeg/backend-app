class AdminController < ApplicationController
  layout 'admin'

  before_action :load_admin_user

  def dashboard
    @new_butler_chats_cnt = Profile.with_has_new_butler_message(true).count
  end

  def suspicious

  end

  def lookup_user
    @profile = Profile.find(params[:uuid])
    redirect_to admin_show_user_path(@profile.uuid)
  end

  def show_user
    @profile = Profile.find params[:uuid]
  end

  private

  def load_admin_user
    # @admin_user = Profile.find(session[:user_uuid]) if session[:user_uuid].present?
    @admin_user = Profile.with_email('vinthanedar@gmail.com').take
  end
end
