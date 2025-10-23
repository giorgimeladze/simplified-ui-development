class Event < ApplicationRecord
  validates :aggregate_id, :aggregate_type, :event_type, :event_data, :version, :occurred_at, presence: true
  
  scope :for_aggregate, ->(aggregate_id, aggregate_type) { 
    where(aggregate_id: aggregate_id, aggregate_type: aggregate_type) 
  }
  scope :by_type, ->(event_type) { where(event_type: event_type) }
  scope :ordered, -> { order(:version) }
  scope :since, ->(time) { where('occurred_at >= ?', time) }
  
  def self.create_event!(aggregate_id, aggregate_type, event_type, event_data, version)
    create!(
      aggregate_id: aggregate_id,
      aggregate_type: aggregate_type,
      event_type: event_type,
      event_data: event_data,
      version: version,
      occurred_at: Time.current
    )
  end
end
