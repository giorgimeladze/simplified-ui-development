class Event < ApplicationRecord
  validates :aggregate_id, :aggregate_type, :event_type, :event_data, :version, :occurred_at, presence: true
  
  scope :for_aggregate, ->(aggregate_id, aggregate_type) { 
    where(aggregate_id: aggregate_id, aggregate_type: aggregate_type) 
  }
  scope :by_type, ->(event_type) { where(event_type: event_type) }
  scope :ordered, -> { order(:version) }
  scope :since, ->(time) { where('occurred_at >= ?', time) }
  
  def self.create_event!(aggregate_id, aggregate_type, event_type, event_data, version, metadata = {})
    create!(
      aggregate_id: aggregate_id,
      aggregate_type: aggregate_type,
      event_type: event_type,
      event_data: event_data,
      version: version,
      occurred_at: Time.current,
      correlation_id: metadata[:correlation_id],
      causation_id: metadata[:causation_id]
    )
  end
  
  def aggregate
    @aggregate ||= aggregate_type.constantize.find(aggregate_id)
  rescue ActiveRecord::RecordNotFound
    nil
  end
  
  def correlation_id
    super || metadata['correlation_id']
  end
  
  def causation_id
    super || metadata['causation_id']
  end
  
  def metadata
    @metadata ||= event_data['metadata'] || {}
  end
  
  def event_data_without_metadata
    event_data.except('metadata')
  end
end
