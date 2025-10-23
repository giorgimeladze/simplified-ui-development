class BaseEvent
  attr_reader :occurred_at, :metadata
  
  def initialize(metadata = {})
    @occurred_at = Time.current
    @metadata = metadata
  end
  
  def to_h
    {
      occurred_at: @occurred_at,
      metadata: @metadata
    }.merge(event_specific_data)
  end
  
  private
  
  def event_specific_data
    # Override in subclasses
    {}
  end
end
