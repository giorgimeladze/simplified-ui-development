require 'securerandom'
class Article2Commands
  class << self
    def create_article(title, content, user)
      aggregate_id = SecureRandom.uuid
      aggregate = Article2Aggregate.new(aggregate_id)
      aggregate.create(title: title, content: content, author_id: user.id)
      repository.store(aggregate, Article2Created, expected_version: :none)
      { success: true, article2_id: aggregate_id }
    end
    
    def submit_article(article2_id, user)
      aggregate = repository.load(Article2Aggregate, article2_id)
      aggregate.submit(actor_id: user.id)
      repository.store(aggregate, Article2Submitted)
      { success: true, article2_id: article2_id }
    end

    def reject_article(article2_id, rejection_feedback, user)
      aggregate = repository.load(Article2Aggregate, article2_id)
      aggregate.reject(rejection_feedback: rejection_feedback, actor_id: user.id)
      repository.store(aggregate, Article2Rejected)
      { success: true, article2_id: article2_id }
    end
    
    def approve_private_article(article2_id, user)
      aggregate = repository.load(Article2Aggregate, article2_id)
      aggregate.approve_private(actor_id: user.id)
      repository.store(aggregate, Article2ApprovedPrivate)
      { success: true, article2_id: article2_id }
    end
    
    def publish_article(article2_id, user)
      aggregate = repository.load(Article2Aggregate, article2_id)
      aggregate.publish(actor_id: user.id)
      repository.store(aggregate, Article2Published)
      { success: true, article2_id: article2_id }
    end
    
    def archive_article(article2_id, user)
      aggregate = repository.load(Article2Aggregate, article2_id)
      aggregate.archive(actor_id: user.id)
      repository.store(aggregate, Article2Archived)
      { success: true, article2_id: article2_id }
    end
    
    def update_article(article2_id, title, content, user)
      aggregate = repository.load(Article2Aggregate, article2_id)
      aggregate.update(title: title, content: content, actor_id: user.id)
      repository.store(aggregate, Article2Updated)
      { success: true, article2_id: article2_id }
    end
    
    def resubmit_article(article2_id, user)
      aggregate = repository.load(Article2Aggregate, article2_id)
      aggregate.submit(actor_id: user.id)
      repository.store(aggregate, Article2Submitted)
      { success: true, article2_id: article2_id }
    end
    
    def make_visible_article(article2_id, user)
      aggregate = repository.load(Article2Aggregate, article2_id)
      aggregate.publish(actor_id: user.id)
      repository.store(aggregate, Article2Published)
      { success: true, article2_id: article2_id }
    end
    
    def make_invisible_article(article2_id, user)
      aggregate = repository.load(Article2Aggregate, article2_id)
      aggregate.approve_private(actor_id: user.id)
      repository.store(aggregate, Article2ApprovedPrivate)
      { success: true, article2_id: article2_id }
    end

    private

    def repository
      @repository ||= EventRepository.new
    end
  end
end
