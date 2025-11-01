class EventRepository
  def initialize(client: Rails.application.config.x.event_store)
    @client = client
  end

  def load(aggregate_class, aggregate_id)
    aggregate = aggregate_class.new(aggregate_id)
    stream = stream_name(aggregate_class, aggregate_id)
    
    # Read all events from the stream and apply them to the aggregate
    events = @client.read.stream(stream).to_a
    events.each do |event|
      aggregate.apply(event)
    end
    
    aggregate
  end

  def store(aggregate, event_class, expected_version: :any)
    stream = stream_name(aggregate.class, aggregate.id)
    
    puts("[RES] Storing to stream=#{stream} unpublished_events=#{aggregate.unpublished_events.map(&:class).join(', ')}")

    # Publish each unpublished event directly to the event store
    event = aggregate.unpublished_events.to_a.last
    return unless event.is_a?(event_class)

    puts("[RES] Publishing event #{event.class.name} with expected_version=#{expected_version}")
    @client.publish(
      event,
      stream_name: stream,
      expected_version: expected_version
    )
    puts("[RES] Publishing event #{event.class.name} with expected_version=#{expected_version}")

    aggregate.instance_variable_get(:@unpublished_events).clear
    puts("[RES] Stored #{aggregate.unpublished_events.count} events to #{stream}")
  end

  private
  
  def stream_name(aggregate_class, aggregate_id)
    category = aggregate_class.name.sub('Aggregate', '')
    "#{category}$#{aggregate_id}"
  end
end