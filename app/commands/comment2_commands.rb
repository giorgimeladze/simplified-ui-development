# frozen_string_literal: true

require 'securerandom'
class Comment2Commands
  class << self
    def create_comment(text, article2_id, user)
      comment2_id = SecureRandom.uuid
      aggregate = Comment2Aggregate.new(comment2_id)
      aggregate.create(text: text, article2_id: article2_id, author_id: user.id)
      repository.store(aggregate, Comment2Created, expected_version: :none)
      { success: true, comment2_id: comment2_id }
    end

    def approve_comment(comment2_id, user)
      aggregate = repository.load(Comment2Aggregate, comment2_id)
      aggregate.approve(actor_id: user.id)
      repository.store(aggregate, Comment2Approved)
      { success: true, comment2_id: comment2_id }
    end

    def reject_comment(comment2_id, rejection_feedback, user)
      return { success: false, errors: 'Rejection feedback is required' } unless rejection_feedback.present?

      aggregate = repository.load(Comment2Aggregate, comment2_id)
      aggregate.reject(rejection_feedback: rejection_feedback, actor_id: user.id)
      repository.store(aggregate, Comment2Rejected)
      { success: true, comment2_id: comment2_id }
    end

    def delete_comment(comment2_id, user)
      aggregate = repository.load(Comment2Aggregate, comment2_id)
      aggregate.delete(actor_id: user.id)
      repository.store(aggregate, Comment2Deleted)
      { success: true, comment2_id: comment2_id }
    end

    def restore_comment(comment2_id, user)
      aggregate = repository.load(Comment2Aggregate, comment2_id)
      aggregate.restore(actor_id: user.id)
      repository.store(aggregate, Comment2Restored)
      { success: true, comment2_id: comment2_id }
    end

    def update_comment(comment2_id, text, user)
      aggregate = repository.load(Comment2Aggregate, comment2_id)
      aggregate.update(text: text, actor_id: user.id)
      repository.store(aggregate, Comment2Updated)
      { success: true, comment2_id: comment2_id }
    end

    private

    def repository
      @repository ||= EventRepository.new
    end
  end
end
