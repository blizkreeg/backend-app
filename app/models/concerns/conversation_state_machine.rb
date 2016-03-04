module ConversationStateMachine
  include Rails.application.routes.url_helpers
  extend ActiveSupport::Concern

  included do
    include AASM

    STATE_ATTRIBUTES = {
      state_endpoint: :string,
      entered_at: :date_time
    }

    jsonb_accessor :state_properties, STATE_ATTRIBUTES

    aasm column: 'state' do
      state :none, initial: true
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
        transitions from: :health_check, to: :none
        transitions from: :ready_to_meet, to: :none
        transitions from: :check_if_meeting, to: :none
        transitions from: :radio_silence, to: :none
      end

      event :check_for_health do
        transitions from: :none, to: :health_check
      end

      event :check_if_ready_to_meet do
        transitions from: :health_check, to: :ready_to_meet
      end

      event :mutual_interest_in_meeting do
        transitions from: :ready_to_meet, to: :show_date_suggestions
      end

      event :check_if_ready_to_move_on do
        transitions from: :none, to: :radio_silence
        transitions from: :health_check, to: :radio_silence
        transitions from: :ready_to_meet, to: :radio_silence
        transitions from: :check_if_meeting, to: :radio_silence
      end

      event :check_if_going_to_meet do
        transitions from: :health_check, to: :check_if_meeting
        transitions from: :ready_to_meet, to: :check_if_meeting
      end

      event :notify_conversation_close do
        transitions from: :radio_silence, to: :close_notice
        transitions from: :check_if_meeting, to: :close_notice
      end
    end
  end

  class_methods do
    def move_conversation_to(id, new_state)
      conv = Conversation.find(id)

      case new_state
      when 'health_check'
        return unless conv.open

        conv.check_for_health!

        Conversation.delay_for(Conversation::READY_TO_MEET_DELAY).move_conversation_to(id, 'ready_to_meet')
      when 'ready_to_meet'
        return unless conv.open

        conv.check_if_ready_to_meet!

        Conversation.delay_for(Conversation::CHECK_IF_MEETING_DELAY).move_conversation_to(id, 'check_if_meeting')
      when 'check_if_meeting'
        return unless conv.open

        conv.check_if_going_to_meet!

        Conversation.delay_for(Conversation::CLOSE_NOTICE_DELAY).move_conversation_to(id, 'close_notice')
      when 'radio_silence'
        return if conv.closes_at <= DateTime.now.utc

        conv.check_if_ready_to_move_on!
      when 'close_notice'
        conv.notify_conversation_close!
      end
    rescue ActiveRecord::RecordNotFound
      EKC.logger.error "Conversation not found, id: #{id}, state: #{conv.state}"
    end
  end

  def record_state_time
    self.entered_at = DateTime.now
  end

  def set_state_endpoint(path=nil)
    self.state_endpoint = path || ''
  end
end
