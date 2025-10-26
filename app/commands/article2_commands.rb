class Article2Commands
  class << self
    def create_article(title, content, user)
      article2 = Article2.new
      article2.title = title
      article2.content = content
      article2.user_id = user.id
      article2.status = 'draft'
      
      event = Article2Created.new(article2.id, title, content, user.id)
      stored_events = EventStore.append_events(article2.id, 'Article2', [event])
      EventBus.publish_events(stored_events)
      
      if article2.save!
        { success: true, article2: article2 }
      else
        { success: false, errors: article2.errors.full_messages }
      end
    end
    
    def submit_article(article2_id, user)
      article2 = Article2.find_by(id: article2_id)
      return { success: false, errors: 'Article not found' } unless article2
      return { success: false, errors: 'Article is not in draft status' } unless article2.status == 'draft'

      event = Article2Submitted.new(article2_id, user.id)
      stored_events = EventStore.append_events(article2_id, 'Article2', [event])
      EventBus.publish_events(stored_events)
      
      update_aggregate(article2, { status: 'review' })
    end
    
    def reject_article(article2_id, rejection_feedback, user)
      article2 = Article2.find_by(id: article2_id)
      return { success: false, errors: 'Article not found' } unless article2
      return { success: false, errors: 'Article is not in review status' } unless article2.status == 'review'

      event = Article2Rejected.new(article2_id, rejection_feedback, user.id)
      stored_events = EventStore.append_events(article2_id, 'Article2', [event])
      EventBus.publish_events(stored_events)
      
      update_aggregate(article2, { status: 'rejected', rejection_feedback: rejection_feedback })
    end
    
    def approve_private_article(article2_id, user)
      article2 = Article2.find_by(id: article2_id)
      return { success: false, errors: 'Article not found' } unless article2
      return { success: false, errors: 'Article is not in review status' } unless article2.status == 'review'

      event = Article2ApprovedPrivate.new(article2_id, user.id)
      stored_events = EventStore.append_events(article2_id, 'Article2', [event])
      EventBus.publish_events(stored_events)
      
      update_aggregate(article2, { status: 'privated' })
    end
    
    def publish_article(article2_id, user)
      article2 = Article2.find_by(id: article2_id)
      return { success: false, errors: 'Article not found' } unless article2
      return { success: false, errors: 'Article is not in review status' } unless article2.status == 'review'

      event = Article2Published.new(article2_id, user.id)
      stored_events = EventStore.append_events(article2_id, 'Article2', [event])
      EventBus.publish_events(stored_events)
      
      update_aggregate(article2, { status: 'published' })
    end
    
    def archive_article(article2_id, user)
      article2 = Article2.find_by(id: article2_id)
      return { success: false, errors: 'Article not found' } unless article2
      return { success: false, errors: 'Article cannot be archived from current status' } unless ['rejected', 'published', 'privated'].include?(article2.status)

      event = Article2Archived.new(article2_id, user.id)
      stored_events = EventStore.append_events(article2_id, 'Article2', [event])
      EventBus.publish_events(stored_events)
      
      update_aggregate(article2, { status: 'archived' })
    end
    
    def update_article(article2_id, title, content, user)
      article2 = Article2.find_by(id: article2_id)
      return { success: false, errors: 'Article not found' } unless article2
      return { success: false, errors: 'Article cannot be updated from current status' } unless ['draft', 'rejected'].include?(article2.status)

      event = Article2Updated.new(article2_id, title, content, user.id)
      stored_events = EventStore.append_events(article2_id, 'Article2', [event])
      EventBus.publish_events(stored_events)
      
      update_aggregate(article2, { title: title, content: content })
    end
    
    def resubmit_article(article2_id, user)
      article2 = Article2.find_by(id: article2_id)
      return { success: false, errors: 'Article not found' } unless article2
      return { success: false, errors: 'Article is not in rejected status' } unless article2.status == 'rejected'

      event = Article2Submitted.new(article2_id, user.id)
      stored_events = EventStore.append_events(article2_id, 'Article2', [event])
      EventBus.publish_events(stored_events)
      
      update_aggregate(article2, { status: 'review' })
    end
    
    def make_visible_article(article2_id, user)
      article2 = Article2.find_by(id: article2_id)
      return { success: false, errors: 'Article not found' } unless article2
      return { success: false, errors: 'Article is not in privated status' } unless article2.status == 'privated'

      event = Article2Published.new(article2_id, user.id)
      stored_events = EventStore.append_events(article2_id, 'Article2', [event])
      EventBus.publish_events(stored_events)
      
      update_aggregate(article2, { status: 'published' })
    end
    
    def make_invisible_article(article2_id, user)
      article2 = Article2.find_by(id: article2_id)
      return { success: false, errors: 'Article not found' } unless article2
      return { success: false, errors: 'Article is not in published status' } unless article2.status == 'published'

      event = Article2ApprovedPrivate.new(article2_id, user.id)
      stored_events = EventStore.append_events(article2_id, 'Article2', [event])
      EventBus.publish_events(stored_events)
      
      update_aggregate(article2, { status: 'privated' })
    end

    private

    def update_aggregate(article2, params)
      if article2.update!(params)
        { success: true, article2: article2 }
      else
        { success: false, errors: article2.errors.full_messages }
      end
    end
  end
end
