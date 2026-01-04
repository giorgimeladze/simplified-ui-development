# frozen_string_literal: true

class StateTransition < ApplicationRecord
  belongs_to :transitionable, polymorphic: true
  belongs_to :user

  # Analytics methods
  def self.transitions_by_event
    group(:event).count
  end
end
