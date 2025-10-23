class EventBus
  include Wisper::Publisher
  
  class << self
    def publish(event)
      new.broadcast(event.class.name.underscore, event)
    end
    
    def publish_events(events)
      events.each { |event| publish(event) }
    end
    
    def publish_with_metadata(event, metadata = {})
      # Add metadata to event if needed
      event_with_metadata = event.dup
      event_with_metadata.instance_variable_set(:@metadata, metadata)
      publish(event_with_metadata)
    end
  end
  
  # Instance methods for Wisper
  def broadcast(event_name, event)
    super(event_name, event)
  rescue => e
    Rails.logger.error "Failed to broadcast event #{event_name}: #{e.message}"
    raise e
  end
end
