class Comment2Commands
  class << self
    def create_comment(text, article2_id, user, metadata = {})
      article2 = Article2.find(article2_id)
      return { success: false, error: 'Article not found' } unless article2
      
      comment2 = Comment2.new
      comment2.id = SecureRandom.uuid
      comment2.text = text
      comment2.article2_id = article2_id
      comment2.user_id = user.id
      comment2.status = 'pending'
      
      # Create domain event
      event = Comment2Created.new(comment2.id, text, article2_id, user.id, metadata)
      
      # Store event and publish
      stored_events = EventStore.append_events(comment2.id, 'Comment2', [event], metadata)
      EventBus.publish_events(stored_events)
      
      # Save the aggregate
      comment2.save!
      { success: true, comment2: comment2 }
    end
    
    def approve_comment(comment2_id, user, metadata = {})
      comment2 = Comment2.find(comment2_id)
      return { success: false, error: 'Comment not found' } unless comment2
      return { success: false, error: 'Comment is not in pending status' } unless comment2.status == 'pending'
      
      # Create domain event
      event = Comment2Approved.new(comment2_id, user.id, metadata)
      
      # Store event and publish
      stored_events = EventStore.append_events(comment2_id, 'Comment2', [event], metadata)
      EventBus.publish_events(stored_events)
      
      # Update aggregate state
      comment2.update!(status: 'approved')
      { success: true, comment2: comment2 }
    end
    
    def reject_comment(comment2_id, rejection_feedback, user, metadata = {})
      comment2 = Comment2.find(comment2_id)
      return { success: false, error: 'Comment not found' } unless comment2
      return { success: false, error: 'Comment is not in pending status' } unless comment2.status == 'pending'
      
      # Create domain event
      event = Comment2Rejected.new(comment2_id, rejection_feedback, user.id, metadata)
      
      # Store event and publish
      stored_events = EventStore.append_events(comment2_id, 'Comment2', [event], metadata)
      EventBus.publish_events(stored_events)
      
      # Update aggregate state
      comment2.update!(status: 'rejected', rejection_feedback: rejection_feedback)
      { success: true, comment2: comment2 }
    end
    
    def delete_comment(comment2_id, user, metadata = {})
      comment2 = Comment2.find(comment2_id)
      return { success: false, error: 'Comment not found' } unless comment2
      return { success: false, error: 'Comment cannot be deleted from current status' } unless ['pending', 'approved', 'rejected'].include?(comment2.status)
      
      # Create domain event
      event = Comment2Deleted.new(comment2_id, user.id, metadata)
      
      # Store event and publish
      stored_events = EventStore.append_events(comment2_id, 'Comment2', [event], metadata)
      EventBus.publish_events(stored_events)
      
      # Update aggregate state
      comment2.update!(status: 'deleted')
      { success: true, comment2: comment2 }
    end
    
    def restore_comment(comment2_id, user, metadata = {})
      comment2 = Comment2.find(comment2_id)
      return { success: false, error: 'Comment not found' } unless comment2
      return { success: false, error: 'Comment is not in deleted status' } unless comment2.status == 'deleted'
      
      # Create domain event
      event = Comment2Restored.new(comment2_id, user.id, metadata)
      
      # Store event and publish
      stored_events = EventStore.append_events(comment2_id, 'Comment2', [event], metadata)
      EventBus.publish_events(stored_events)
      
      # Update aggregate state
      comment2.update!(status: 'pending')
      { success: true, comment2: comment2 }
    end
    
    def update_comment(comment2_id, text, user, metadata = {})
      comment2 = Comment2.find(comment2_id)
      return { success: false, error: 'Comment not found' } unless comment2
      return { success: false, error: 'Comment cannot be updated from current status' } unless ['pending', 'approved', 'rejected'].include?(comment2.status)
      
      # Create domain event
      event = Comment2Updated.new(comment2_id, text, user.id, metadata)
      
      # Store event and publish
      stored_events = EventStore.append_events(comment2_id, 'Comment2', [event], metadata)
      EventBus.publish_events(stored_events)
      
      # Update aggregate state
      comment2.update!(text: text)
      { success: true, comment2: comment2 }
    end
  end
end
