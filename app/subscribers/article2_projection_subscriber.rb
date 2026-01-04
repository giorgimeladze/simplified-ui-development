# frozen_string_literal: true

class Article2ProjectionSubscriber
  def call(event)
    Rails.logger.debug("[RES] Article2ProjectionSubscriber handling #{event.class.name} #{event.event_id}")
    ::Article2Projection.apply(event)
  rescue StandardError => e
    Rails.logger.error("[RES] Article2ProjectionSubscriber error: #{e.class} #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    raise
  end
end
