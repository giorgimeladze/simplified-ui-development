class Article2Listeners
  include Wisper::Publisher
  
  def self.subscribe_to(event_bus)
    event_bus.subscribe(self.new)
  end
  
  def article2_created(event)
    puts "Article2 created: #{event.article2_id} by user #{event.user_id}"
  end
  
  def article2_submitted(event)
    puts "Article2 submitted for review: #{event.article2_id}"
  end
  
  def article2_rejected(event)
    puts "Article2 rejected: #{event.article2_id} - #{event.rejection_feedback}"
  end
  
  def article2_approved_private(event)
    puts "Article2 approved as private: #{event.article2_id}"
  end
  
  def article2_published(event)
    puts "Article2 published: #{event.article2_id}"
  end
  
  def article2_archived(event)
    puts "Article2 archived: #{event.article2_id}"
  end
  
  def article2_updated(event)
    puts "Article2 updated: #{event.article2_id}"
  end
end
