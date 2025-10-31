class EventRepository
  def initialize(client: Rails.application.config.x.event_store)
    @repository = AggregateRoot::Repository.new(client)
    @client = client
  end

  def load(aggregate_class, aggregate_id)
    aggregate = aggregate_class.new(aggregate_id)
    @repository.load(aggregate, stream_name(aggregate_class, aggregate_id))
  end

  def store(aggregate, expected_version: :any)
    stream = stream_name(aggregate.class, aggregate.id)
    puts("[RES] Storing to stream=#{stream} unpublished_events=#{aggregate.unpublished_events.map(&:class).join(', ')}")

    # Store without metadata; API expects only (aggregate, expected_version:)
    @repository.store(aggregate, expected_version: expected_version)

    puts("[RES] Stored events to #{stream}")
  end

  def stream_name(aggregate_class, aggregate_id)
    category = aggregate_class.name.sub('Aggregate', '')
    "#{category}$#{aggregate_id}"
  end
  private :stream_name
end


