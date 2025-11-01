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

  def store(aggregate, expected_version: :any)
    stream = stream_name(aggregate.class, aggregate.id)
    unpublished_events = aggregate.unpublished_events
    
    puts("[RES] Storing to stream=#{stream} unpublished_events=#{unpublished_events.map(&:class).join(', ')}")

    # Publish each unpublished event directly to the event store
    unpublished_events.each_with_index do |event, index|
      ev = (index == 0) ? expected_version : :auto  # Use :auto for subsequent events
      
      puts("[RES] Publishing event #{event.class.name} with expected_version=#{ev}")
      @client.publish(
        event,
        stream_name: stream,
        expected_version: ev
      )
      puts("[RES] Published event #{event.class.name}")
    end

    puts("[RES] Stored #{unpublished_events.count} events to #{stream}")
  end

  private
  
  def stream_name(aggregate_class, aggregate_id)
    category = aggregate_class.name.sub('Aggregate', '')
    "#{category}$#{aggregate_id}"
  end
end