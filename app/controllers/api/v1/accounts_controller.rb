class Api::V1::AccountsController < ApiController
  respond_to :json

  def send_push_notification
    if params[:data][:single_user]
      uuid = params[:data][:uuid]
      notification_type = params[:data][:notification_type]
      notification_params = params[:data][:notification_params]

      # flags
      if notification_type == 'new_conversation_message'
        Conversation.delay.set_message_waiting(params[:data][:conversation_uuid], uuid)
        Profile.delay.update(uuid, has_messages_waiting: true)
      end

      # queue notification
      PushNotifier.delay.record_event(uuid, notification_type, notification_params)

      render 'api/v1/shared/nodata', status: 200
    end
  rescue StandardError => e
    respond_with_error(e.message, 500)
  end

  def update_user_new_butler_message
    if params[:data][:uuid]
      Profile.update(params[:data][:uuid], needs_butler_attention: true)
    else
      EKC.logger.error "UUID is null"
    end

    render 'api/v1/shared/nodata', status: 200
  rescue StandardError => e
    respond_with_error(e.message, 500)
  end
end
