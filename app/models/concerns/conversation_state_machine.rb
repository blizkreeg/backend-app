module ConversationStateMachine
  include Rails.application.routes.url_helpers
  extend ActiveSupport::Concern

  included do
    include AASM

    STATE_ATTRIBUTES = {
      state_endpoint: :string,
      entered_at: :date_time
    }

    # store_accessor :state_properties, *(STATE_ATTRIBUTES.keys.map(&:to_sym))
    # jsonb_attr_helper :state_properties, STATE_ATTRIBUTES
    jsonb_accessor :state_properties, STATE_ATTRIBUTES

    aasm column: 'state' do
      state :none, initial: true
      state :info
      state :health_check
      state :ready_to_meet
      state :show_date_suggestions
      state :radio_silence
      state :check_if_meeting
      state :close_notice

      after_all_transitions :record_state_time
      after_all_transitions Proc.new { |*args| set_state_endpoint(*args) }

      event :reset do
        transitions from: :none, to: :none
        transitions from: :info, to: :none
        transitions from: :health_check, to: :none
        transitions from: :ready_to_meet, to: :none
        transitions from: :check_if_meeting, to: :none
        transitions from: :radio_silence, to: :none
      end

      event :info do
        transitions from: :none, to: :info
      end

      event :check_for_health do
        transitions from: :none, to: :health_check
        transitions from: :info, to: :health_check
      end

      event :check_if_ready_to_meet do
        transitions from: :health_check, to: :ready_to_meet
      end

      event :mutual_interest_in_meeting do
        transitions from: :ready_to_meet, to: :show_date_suggestions
      end

      event :check_if_ready_to_move_on do
        transitions from: :none, to: :radio_silence
        transitions from: :info, to: :radio_silence
        transitions from: :health_check, to: :radio_silence
        transitions from: :ready_to_meet, to: :radio_silence
        transitions from: :check_if_meeting, to: :radio_silence
        transitions from: :show_date_suggestions, to: :radio_silence
      end

      event :check_if_going_to_meet do
        transitions from: :none, to: :check_if_meeting
        transitions from: :info, to: :check_if_meeting
        transitions from: :ready_to_meet, to: :check_if_meeting
        transitions from: :show_date_suggestions, to: :check_if_meeting
      end

      event :notify_conversation_close do
        transitions from: :none, to: :close_notice
        transitions from: :info, to: :close_notice
        transitions from: :radio_silence, to: :close_notice
        transitions from: :check_if_meeting, to: :close_notice
      end
    end
  end

  class_methods do
    def move_conversation_to(id, new_state)
      conv = Conversation.find(id)

      return if %w(health_check ready_to_meet show_date_suggestions check_if_meeting close_notice).include?(new_state) && conv.closed?

      case new_state
      when 'none'
        conv.reset!(:none)
      when 'info'
        conv.info!
      when 'health_check'
        return if conv.health_check?

        conv.check_for_health!
        PushNotifier.delay.record_event(conv.initiator.uuid, 'conv_health_check', name: conv.responder.firstname)
        PushNotifier.delay.record_event(conv.responder.uuid, 'conv_health_check', name: conv.initiator.firstname)
      when 'ready_to_meet'
        return if conv.ready_to_meet?

        conv.check_if_ready_to_meet!
        PushNotifier.delay.record_event(conv.initiator.uuid, 'conv_ready_to_meet', name: conv.responder.firstname)
        PushNotifier.delay.record_event(conv.responder.uuid, 'conv_ready_to_meet', name: conv.initiator.firstname)
      when 'show_date_suggestions'
        return if conv.show_date_suggestions?

        conv.mutual_interest_in_meeting!
        PushNotifier.delay.record_event(conv.initiator.uuid, 'conv_date_suggestions', name: conv.responder.firstname)
        PushNotifier.delay.record_event(conv.responder.uuid, 'conv_date_suggestions', name: conv.initiator.firstname)
      when 'check_if_meeting'
        return if conv.check_if_meeting?

        conv.check_if_going_to_meet!
        PushNotifier.delay.record_event(conv.initiator.uuid, 'conv_are_you_meeting', name: conv.responder.firstname)
        PushNotifier.delay.record_event(conv.responder.uuid, 'conv_are_you_meeting', name: conv.initiator.firstname)
      when 'radio_silence'
        return if conv.closes_at <= DateTime.now.utc
        return if conv.radio_silence?

        conv.check_if_ready_to_move_on!
      when 'close_notice'
        return if conv.close_notice?

        conv.notify_conversation_close!

        PushNotifier.delay.record_event(conv.initiator.uuid, 'conv_close_notice', name: conv.responder.firstname)
        PushNotifier.delay.record_event(conv.responder.uuid, 'conv_close_notice', name: conv.initiator.firstname)
      end
    rescue ActiveRecord::RecordNotFound
      EKC.logger.error "Conversation not found, id: #{id}"
    end
  end

  def record_state_time
    self.entered_at = DateTime.now
  end

  def set_state_endpoint(path=nil)
    self.state_endpoint = path || ''
  end
end
