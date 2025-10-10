module HasStateTransitions
  extend ActiveSupport::Concern

  included do
    has_many :state_transitions, as: :transitionable, dependent: :destroy

    # AASM callback - logs after any state transition
    after_commit :log_state_transition
  end

  private

  def log_state_transition
    # Access the transition metadata from AASM
    from_state = aasm.from_state
    to_state = aasm.to_state
    event_name = aasm.current_event
    
    return unless from_state && to_state && event_name
    
    StateTransition.create!(
      transitionable: self,
      from_state: from_state.to_s,
      to_state: to_state.to_s,
      event: event_name.to_s,
      user: user
    )
  rescue StandardError => e
    Rails.logger.error "Failed to log state transition: #{e.message}"
  end
end
