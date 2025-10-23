class EventStore
  def self.append_events(aggregate_id, aggregate_type, events)
    return [] if events.empty?
    
    stored_events = []
    
    Event.transaction do
      current_version = get_current_version(aggregate_id, aggregate_type)
      
      events.each_with_index do |event, index|
        version = current_version + index + 1
        
        stored_event = Event.create_event!(
          aggregate_id,
          aggregate_type,
          event.class.name,
          event.to_h,
          version
        )
        
        stored_events << stored_event
      end
    end
    
    stored_events
  end
  
  def self.get_events(aggregate_id, aggregate_type, from_version = 0)
    Event.for_aggregate(aggregate_id, aggregate_type)
          .where('version > ?', from_version)
          .ordered
  end

  private
  
  def self.get_current_version(aggregate_id, aggregate_type)
    Event.for_aggregate(aggregate_id, aggregate_type)
          .maximum(:version) || 0
  end
end
