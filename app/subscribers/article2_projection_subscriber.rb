class Article2ProjectionSubscriber
  def call(event)
    puts("[RES] Article2ProjectionSubscriber handling #{event.class.name} #{event.event_id}")
    ::Article2Projection.apply(event)
  rescue => e
    puts("[RES] Article2ProjectionSubscriber error: #{e.class} #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    raise
  end
end


