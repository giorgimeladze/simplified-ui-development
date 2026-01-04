# frozen_string_literal: true

class EventsController < ApplicationController
  def index
    authorize :event, :index?

    @events = ActiveRecord::Base.connection.execute(<<~SQL)
      SELECT *
      FROM event_store_events
      ORDER BY created_at DESC
    SQL
    @events = @events.map { |event| format_event(event) }

    respond_to do |format|
      format.html { render :index }
      format.json { render json: { events: @events } }
    end
  end

  private

  def format_event(event)
    event = event.deep_symbolize_keys
    {
      event_id: event[:event_id],
      event_type: event[:event_type],
      data: event[:data],
      metadata: event[:metadata],
      created_at: event[:created_at]
    }
  end
end
