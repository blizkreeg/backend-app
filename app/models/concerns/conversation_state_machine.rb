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
      state :conversation_question
      state :ready_to_meet
      state :date_suggestions
      state :radio_silence
      state :check_if_meeting

      # after_all_transitions :record_state_time
      # after_all_transitions Proc.new { |*args| set_state_endpoint(*args) }
    end
  end

  def record_state_time
    self.entered_at = DateTime.now
  end

  def set_state_endpoint(path='')
    self.state_endpoint = path
  end
end
