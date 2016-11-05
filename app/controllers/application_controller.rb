require "google/api_client"
require "google_drive"
require 'openssl'

class ApplicationController < ActionController::Base
  # before_action :prepare_exception_notifier

  after_action :log_response

  def route_not_found
    render file: 'public/404.html', layout: false, status: :not_found
  end

  private

  def prepare_exception_notifier
    request.env["exception_notifier.exception_data"] = {
      :request_path => request.fullpath
    }

    request.env["exception_notifier.exception_data"].merge!({
      :profile_uuid => @current_profile.uuid,
    }) if @current_profile.present?
  end

  def log_response
    if response.content_type == 'application/json'
      EKC.logger.debug "REQUEST  (#{@current_profile.try(:uuid) || 'noauth'}): #{request.fullpath}"
      EKC.logger.debug "RESPONSE (#{@current_profile.try(:uuid) || 'noauth'}): #{response.body}"
    end
  end
end
