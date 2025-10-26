class EventsController < ApplicationController
  def index
    authorize Event, :index?
    @events = Event.all.order(occurred_at: :desc)
    
    respond_to do |format|
      format.html { render :index }
      format.json { render json: { events: @events } }
    end
  end
end
