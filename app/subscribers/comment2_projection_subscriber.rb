# frozen_string_literal: true

class Comment2ProjectionSubscriber
  def call(event)
    Rails.logger.debug("[RES] Comment2ProjectionSubscriber handling #{event.class.name} #{event.event_id}")
    ::Comment2Projection.apply(event)
  end
end
