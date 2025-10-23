class EventStore
  class << self
    def append_events(aggregate_id, aggregate_type, events, metadata = {})
      return [] if events.empty?
      
      correlation_id = metadata[:correlation_id] || SecureRandom.uuid
      causation_id = metadata[:causation_id]
      
      stored_events = []
      
      Event.transaction do
        current_version = get_current_version(aggregate_id, aggregate_type)
        
        events.each_with_index do |event, index|
          version = current_version + index + 1
          
          stored_event = Event.create_event!(
            aggregate_id,
            aggregate_type,
            event.class.name,
            event.to_h.merge(metadata: metadata),
            version,
            {
              correlation_id: correlation_id,
              causation_id: causation_id
            }
          )
          
          stored_events << stored_event
        end
      end
      
      stored_events
    end
    
    def get_events(aggregate_id, aggregate_type, from_version = 0)
      Event.for_aggregate(aggregate_id, aggregate_type)
           .where('version > ?', from_version)
           .ordered
    end
    
    def get_events_since(aggregate_id, aggregate_type, since_time)
      Event.for_aggregate(aggregate_id, aggregate_type)
           .since(since_time)
           .ordered
    end
    
    def get_current_version(aggregate_id, aggregate_type)
      Event.for_aggregate(aggregate_id, aggregate_type)
           .maximum(:version) || 0
    end
    
    def get_events_by_type(event_type, limit = 100)
      Event.by_type(event_type)
           .order(:occurred_at)
           .limit(limit)
    end
    
    def get_events_by_correlation(correlation_id)
      Event.where(correlation_id: correlation_id)
           .order(:occurred_at)
    end
    
    def get_events_by_causation(causation_id)
      Event.where(causation_id: causation_id)
           .order(:occurred_at)
    end
    
    def get_all_events(limit = 1000, offset = 0)
      Event.order(:occurred_at, :id)
           .limit(limit)
           .offset(offset)
    end
    
    def get_events_for_aggregate_type(aggregate_type, limit = 100)
      Event.where(aggregate_type: aggregate_type)
           .order(:occurred_at)
           .limit(limit)
    end
    
    def delete_events(aggregate_id, aggregate_type)
      Event.for_aggregate(aggregate_id, aggregate_type).delete_all
    end
    
    def event_exists?(aggregate_id, aggregate_type, event_type)
      Event.for_aggregate(aggregate_id, aggregate_type)
           .by_type(event_type)
           .exists?
    end
    
    def get_events_count(aggregate_id, aggregate_type)
      Event.for_aggregate(aggregate_id, aggregate_type).count
    end
    
    def get_events_count_by_type(event_type)
      Event.by_type(event_type).count
    end
  end
end
