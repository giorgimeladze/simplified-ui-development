class Article2Commands
  class << self
    def create_article(title, content, user, metadata = {})
      article2 = Article2.new
      article2.id = SecureRandom.uuid
      article2.title = title
      article2.content = content
      article2.user_id = user.id
      article2.status = 'draft'
      
      # Create domain event
      event = Article2Created.new(article2.id, title, content, user.id, metadata)
      
      # Store event and publish
      stored_events = EventStore.append_events(article2.id, 'Article2', [event], metadata)
      EventBus.publish_events(stored_events)
      
      # Save the aggregate
      article2.save!
      article2
    end
    
    def submit_article(article2_id, user, metadata = {})
      article2 = Article2.find(article2_id)
      return { success: false, error: 'Article not found' } unless article2
      return { success: false, error: 'Article is not in draft status' } unless article2.status == 'draft'
      
      # Create domain event
      event = Article2Submitted.new(article2_id, user.id, metadata)
      
      # Store event and publish
      stored_events = EventStore.append_events(article2_id, 'Article2', [event], metadata)
      EventBus.publish_events(stored_events)
      
      # Update aggregate state
      article2.update!(status: 'review')
      { success: true, article2: article2 }
    end
    
    def reject_article(article2_id, rejection_feedback, user, metadata = {})
      article2 = Article2.find(article2_id)
      return { success: false, error: 'Article not found' } unless article2
      return { success: false, error: 'Article is not in review status' } unless article2.status == 'review'
      
      # Create domain event
      event = Article2Rejected.new(article2_id, rejection_feedback, user.id, metadata)
      
      # Store event and publish
      stored_events = EventStore.append_events(article2_id, 'Article2', [event], metadata)
      EventBus.publish_events(stored_events)
      
      # Update aggregate state
      article2.update!(status: 'rejected', rejection_feedback: rejection_feedback)
      { success: true, article2: article2 }
    end
    
    def approve_private_article(article2_id, user, metadata = {})
      article2 = Article2.find(article2_id)
      return { success: false, error: 'Article not found' } unless article2
      return { success: false, error: 'Article is not in review status' } unless article2.status == 'review'
      
      # Create domain event
      event = Article2ApprovedPrivate.new(article2_id, user.id, metadata)
      
      # Store event and publish
      stored_events = EventStore.append_events(article2_id, 'Article2', [event], metadata)
      EventBus.publish_events(stored_events)
      
      # Update aggregate state
      article2.update!(status: 'privated')
      { success: true, article2: article2 }
    end
    
    def publish_article(article2_id, user, metadata = {})
      article2 = Article2.find(article2_id)
      return { success: false, error: 'Article not found' } unless article2
      return { success: false, error: 'Article is not in review status' } unless article2.status == 'review'
      
      # Create domain event
      event = Article2Published.new(article2_id, user.id, metadata)
      
      # Store event and publish
      stored_events = EventStore.append_events(article2_id, 'Article2', [event], metadata)
      EventBus.publish_events(stored_events)
      
      # Update aggregate state
      article2.update!(status: 'published')
      { success: true, article2: article2 }
    end
    
    def archive_article(article2_id, user, metadata = {})
      article2 = Article2.find(article2_id)
      return { success: false, error: 'Article not found' } unless article2
      return { success: false, error: 'Article cannot be archived from current status' } unless ['rejected', 'published', 'privated'].include?(article2.status)
      
      # Create domain event
      event = Article2Archived.new(article2_id, user.id, metadata)
      
      # Store event and publish
      stored_events = EventStore.append_events(article2_id, 'Article2', [event], metadata)
      EventBus.publish_events(stored_events)
      
      # Update aggregate state
      article2.update!(status: 'archived')
      { success: true, article2: article2 }
    end
    
    def update_article(article2_id, title, content, user, metadata = {})
      article2 = Article2.find(article2_id)
      return { success: false, error: 'Article not found' } unless article2
      return { success: false, error: 'Article cannot be updated from current status' } unless ['draft', 'rejected'].include?(article2.status)
      
      # Create domain event
      event = Article2Updated.new(article2_id, title, content, user.id, metadata)
      
      # Store event and publish
      stored_events = EventStore.append_events(article2_id, 'Article2', [event], metadata)
      EventBus.publish_events(stored_events)
      
      # Update aggregate state
      article2.update!(title: title, content: content)
      { success: true, article2: article2 }
    end
    
    def resubmit_article(article2_id, user, metadata = {})
      article2 = Article2.find(article2_id)
      return { success: false, error: 'Article not found' } unless article2
      return { success: false, error: 'Article is not in rejected status' } unless article2.status == 'rejected'
      
      # Create domain event (reuse submitted event)
      event = Article2Submitted.new(article2_id, user.id, metadata)
      
      # Store event and publish
      stored_events = EventStore.append_events(article2_id, 'Article2', [event], metadata)
      EventBus.publish_events(stored_events)
      
      # Update aggregate state
      article2.update!(status: 'review', rejection_feedback: nil)
      { success: true, article2: article2 }
    end
    
    def make_visible_article(article2_id, user, metadata = {})
      article2 = Article2.find(article2_id)
      return { success: false, error: 'Article not found' } unless article2
      return { success: false, error: 'Article is not in privated status' } unless article2.status == 'privated'
      
      # Create domain event (reuse published event)
      event = Article2Published.new(article2_id, user.id, metadata)
      
      # Store event and publish
      stored_events = EventStore.append_events(article2_id, 'Article2', [event], metadata)
      EventBus.publish_events(stored_events)
      
      # Update aggregate state
      article2.update!(status: 'published')
      { success: true, article2: article2 }
    end
    
    def make_invisible_article(article2_id, user, metadata = {})
      article2 = Article2.find(article2_id)
      return { success: false, error: 'Article not found' } unless article2
      return { success: false, error: 'Article is not in published status' } unless article2.status == 'published'
      
      # Create domain event (reuse approved private event)
      event = Article2ApprovedPrivate.new(article2_id, user.id, metadata)
      
      # Store event and publish
      stored_events = EventStore.append_events(article2_id, 'Article2', [event], metadata)
      EventBus.publish_events(stored_events)
      
      # Update aggregate state
      article2.update!(status: 'privated')
      { success: true, article2: article2 }
    end
  end
end
