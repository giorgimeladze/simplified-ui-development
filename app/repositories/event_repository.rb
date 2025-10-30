class EventRepository
  def initialize(client: Rails.application.config.x.event_store)
    @repository = AggregateRoot::Repository.new(client)
    @client = client
  end

  def load(aggregate_class, aggregate_id)
    @repository.load(aggregate_class.new(aggregate_id), stream_name(aggregate_class, aggregate_id))
  end

  def store(aggregate, expected_version: :auto, metadata: {})
    @repository.store(aggregate, stream_name(aggregate.class, aggregate.id), expected_version: expected_version, metadata: metadata)
  end

  def stream_name(aggregate_class, aggregate_id)
    category = aggregate_class.name.sub('Aggregate', '')
    "#{category}$#{aggregate_id}"
  end
  private :stream_name
end


