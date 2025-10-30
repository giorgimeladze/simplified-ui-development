class EventRepository
  def initialize(client: Rails.application.config.x.event_store)
    @repository = AggregateRoot::Repository.new(client)
    @client = client
  end

  def load(aggregate_class, aggregate_id)
    @repository.load(aggregate_class.new(aggregate_id), stream_name(aggregate_class, aggregate_id))
  end

  def store(aggregate, expected_version: :auto, metadata: {})
    stream = stream_name(aggregate.class, aggregate.id)
    if metadata && !metadata.empty?
      @client.with_metadata(metadata) do
        @repository.store(aggregate, stream, expected_version: expected_version)
      end
    else
      @repository.store(aggregate, stream, expected_version: expected_version)
    end
  end

  def stream_name(aggregate_class, aggregate_id)
    category = aggregate_class.name.sub('Aggregate', '')
    "#{category}$#{aggregate_id}"
  end
  private :stream_name
end


