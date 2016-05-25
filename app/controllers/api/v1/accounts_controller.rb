class Api::V1::AccountsController < ApplicationController
  respond_to :json

  def send_push_notification
    if params[:data][:single_user]
      uuid = params[:data][:uuid]
      notification_type = params[:data][:notification_type]
      notification_params = params[:data][:notification_params]

      PushNotifier.delay.record_event(uuid, notification_type, notification_params)

      render 'api/v1/shared/nodata', status: 200
    end
  rescue StandardError => e
    respond_with_error(e.message, 500)
  end

  def update_user_new_butler_message
    if params[:data][:uuid]
      Profile.update(params[:data][:uuid], has_new_butler_message: true)
    else
      EKC.logger.error "UUID is null"
    end

    render 'api/v1/shared/nodata', status: 200
  rescue StandardError => e
    respond_with_error(e.message, 500)
  end
end
