class StateTransitionsController < ApplicationController
  def index
    authorize StateTransition, :index?
    @state_transitions = StateTransition.all
    
    respond_to do |format|
      format.html { render :index }
      format.json { render json: { state_transitions: @state_transitions } }
    end
  end
end