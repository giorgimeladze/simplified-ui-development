class Comment2Listeners
  include Wisper::Publisher
  
  def self.subscribe_to(event_bus)
    event_bus.subscribe(self.new)
  end
  
  def comment2_created(event)
    puts "Comment2 created: #{event.comment2_id} on article #{event.article2_id} by user #{event.user_id}"
  end
  
  def comment2_approved(event)
    puts "Comment2 approved: #{event.comment2_id}"
  end
  
  def comment2_rejected(event)
    puts "Comment2 rejected: #{event.comment2_id} - #{event.rejection_feedback}"
  end
  
  def comment2_deleted(event)
    puts "Comment2 deleted: #{event.comment2_id}"
  end
  
  def comment2_restored(event)
    puts "Comment2 restored: #{event.comment2_id}"
  end
  
  def comment2_updated(event)
    puts "Comment2 updated: #{event.comment2_id}"
  end
end
