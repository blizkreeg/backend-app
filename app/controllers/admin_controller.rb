class AdminController < ApplicationController
  layout 'admin'

  before_action :load_admin_user

  def dashboard
  end

  def lookup_user
    @profile = Profile.find params[:uuid]
  end

  private

  def load_admin_user
    # @admin_user = Profile.find(session[:user_uuid]) if session[:user_uuid].present?
    @admin_user = Profile.with_email('vinthanedar@gmail.com').take
  end
end
