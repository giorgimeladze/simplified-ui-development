class BaseEvent
  attr_reader :occurred_at
  
  def initialize()
    @occurred_at = Time.current
  end
  
  def to_h
    {
      occurred_at: @occurred_at
    }.merge(event_specific_data)
  end
  
  private
  
  def event_specific_data
    {}
  end
end
