class StateTransitionsController < ApplicationController
  def index
    authorize StateTransition, :index?
    @state_transitions = StateTransition.all
  end
end