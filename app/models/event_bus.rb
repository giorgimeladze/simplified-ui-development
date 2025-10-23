class EventBus
  include Wisper::Publisher
  
  def self.publish_events(events)
    events.each { |event| publish(event) }
  end

  def broadcast(event_name, event)
    super(event_name, event)
  rescue => e
    puts "Failed to broadcast event #{event_name}: #{e.message}"
    raise e
  end

  private

  def self.publish(event)
    new.broadcast(event.class.name.underscore, event)
  end
end
