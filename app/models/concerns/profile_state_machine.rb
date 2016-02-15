module ProfileStateMachine
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
      state :waiting_for_matches
      state :has_matches
      state :show_matches
      state :mutual_match
      state :waiting_for_matches_and_response
      state :has_matches_and_waiting_for_response
      state :show_matches_and_waiting_for_response
      state :in_conversation
      state :post_date_feedback

      after_all_transitions :record_state_time
      after_all_transitions Proc.new { |*args| set_state_endpoint(*args) }

      event :signed_up do
        transitions from: :none, to: :waiting_for_matches
      end

      event :new_matches do
        transitions from: :waiting_for_matches, to: :has_matches
      end

      event :deliver_matches do
        transitions from: :has_matches, to: :show_matches
      end

      event :decided_on_matches do
        transitions from: :show_matches, to: :waiting_for_matches
      end

      event :got_mutual_like do
        transitions from: :waiting_for_matches, to: :mutual_match
        transitions from: :has_matches, to: :mutual_match
        transitions from: :show_matches, to: :mutual_match
      end

      event :got_first_message do
        transitions from: :waiting_for_matches, to: :mutual_match
        transitions from: :has_matches, to: :mutual_match
        transitions from: :show_matches, to: :mutual_match
      end

      event :started_conversation do
        transitions from: :mutual_match, to: :waiting_for_matches_and_response
      end

      event :conversation_mode do
        transitions from: :mutual_match, to: :in_conversation
        transitions from: :waiting_for_matches_and_response, to: :in_conversation
        transitions from: :has_matches_and_waiting_for_response, to: :in_conversation
        transitions from: :show_matches_and_waiting_for_response, to: :in_conversation
        transitions from: :in_conversation, to: :in_conversation
      end

      event :unmatch do
        transitions from: :mutual_match, to: :waiting_for_matches
        transitions from: :in_conversation, to: :waiting_for_matches
      end
    end
  end

  def record_state_time
    self.entered_at = DateTime.now
  end

  def set_state_endpoint(path='')
    self.state_endpoint = path
  end
end
