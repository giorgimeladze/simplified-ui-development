class Comment2Commands
  class << self
    def create_comment(text, article2_id, user)
      article2 = Article2.find_by(id: article2_id)
      return { success: false, errors: 'Article not found' } unless article2
      
      comment2 = Comment2.new
      comment2.text = text
      comment2.article2_id = article2_id
      comment2.user_id = user.id
      comment2.status = 'pending'

      event = Comment2Created.new(comment2.id, text, article2_id, user.id)
      stored_events = EventStore.append_events(comment2.id, 'Comment2', [event])
      EventBus.publish_events(stored_events)

      if comment2.save!
        { success: true, comment2: comment2 }
      else
        { success: false, errors: comment2.errors.full_messages }
      end
    end
    
    def approve_comment(comment2_id, user)
      comment2 = Comment2.find(comment2_id)
      return { success: false, errors: 'Comment not found' } unless comment2
      return { success: false, errors: 'Comment is not in pending status' } unless comment2.status == 'pending'

      event = Comment2Approved.new(comment2_id, user.id )
      stored_events = EventStore.append_events(comment2_id, 'Comment2', [event])
      EventBus.publish_events(stored_events)
      
      update_aggregate(comment2, { status: 'approved' })
    end
    
    def reject_comment(comment2_id, rejection_feedback, user)
      comment2 = Comment2.find(comment2_id)
      return { success: false, errors: 'Comment not found' } unless comment2
      return { success: false, errors: 'Rejection feedback is required' } unless rejection_feedback.present?
      return { success: false, errors: 'Comment is not in pending status' } unless comment2.status == 'pending'

      event = Comment2Rejected.new(comment2_id, rejection_feedback, user.id)
      stored_events = EventStore.append_events(comment2_id, 'Comment2', [event])
      EventBus.publish_events(stored_events)
      
      update_aggregate(comment2, { status: 'rejected', rejection_feedback: rejection_feedback })
    end
    
    def delete_comment(comment2_id, user)
      comment2 = Comment2.find(comment2_id)
      return { success: false, errors: 'Comment not found' } unless comment2
      return { success: false, errors: 'Comment cannot be deleted from current status' } unless ['pending', 'approved', 'rejected'].include?(comment2.status)

      event = Comment2Deleted.new(comment2_id, user.id)
      stored_events = EventStore.append_events(comment2_id, 'Comment2', [event])
      EventBus.publish_events(stored_events)
      
      update_aggregate(comment2, { status: 'deleted' })
    end
    
    def restore_comment(comment2_id, user)
      comment2 = Comment2.find(comment2_id)
      return { success: false, errors: 'Comment not found' } unless comment2
      return { success: false, errors: 'Comment is not in deleted status' } unless comment2.status == 'deleted'
      
      event = Comment2Restored.new(comment2_id, user.id)
      stored_events = EventStore.append_events(comment2_id, 'Comment2', [event])
      EventBus.publish_events(stored_events)

      update_aggregate(comment2, { status: 'pending' })
    end
    
    def update_comment(comment2_id, text, user)
      comment2 = Comment2.find(comment2_id)
      return { success: false, errors: 'Comment not found' } unless comment2
      return { success: false, errors: 'Comment can only be updated when rejected' } unless comment2.status == 'rejected'

      event = Comment2Updated.new(comment2_id, text, user.id)
      stored_events = EventStore.append_events(comment2_id, 'Comment2', [event])
      EventBus.publish_events(stored_events)
      
      update_aggregate(comment2, { text: text, status: 'pending' })
    end

    private

    def update_aggregate(comment2, params)
      if comment2.update!(params)
        { success: true, comment2: comment2 }
      else
        { success: false, errors: comment2.errors.full_messages }
      end
    end
  end
end
