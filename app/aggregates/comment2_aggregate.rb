class Comment2Aggregate
  include AggregateRoot

  attr_reader :id, :article2_id, :author_id, :text, :status, :rejection_feedback

  def initialize(id)
    @id = id
    @status = 'unknown'
  end

  def create(text:, article2_id:, author_id:)
    raise_standard_error('already created') unless @status == 'unknown'
    apply Comment2Created.new(data: {
      comment2_id: id,
      text: text,
      article2_id: article2_id,
      user_id: author_id
    })
  end

  def approve(actor_id:)
    ensure_in_states(%w[pending])
    apply Comment2Approved.new(data: {
      comment2_id: id,
      user_id: actor_id
    })
  end

  def reject(rejection_feedback:, actor_id:)
    ensure_in_states(%w[pending])
    apply Comment2Rejected.new(data: {
      comment2_id: id,
      rejection_feedback: rejection_feedback,
      user_id: actor_id
    })
  end

  def delete(actor_id:)
    ensure_in_states(%w[pending approved rejected])
    apply Comment2Deleted.new(data: {
      comment2_id: id,
      user_id: actor_id
    })
  end

  def restore(actor_id:)
    ensure_in_states(%w[deleted])
    apply Comment2Restored.new(data: {
      comment2_id: id,
      user_id: actor_id
    })
  end

  def update(text:, actor_id:)
    ensure_in_states(%w[rejected])
    apply Comment2Updated.new(data: {
      comment2_id: id,
      text: text,
      user_id: actor_id
    })
  end

  on Comment2Created do |event|
    @text = event.data.fetch(:text)
    @article2_id = event.data.fetch(:article2_id)
    @author_id = event.data.fetch(:user_id)
    @status = 'pending'
    @rejection_feedback = nil
  end

  on Comment2Approved do |_event|
    @status = 'approved'
  end

  on Comment2Rejected do |event|
    @status = 'rejected'
    @rejection_feedback = event.data.fetch(:rejection_feedback)
  end

  on Comment2Deleted do |_event|
    @status = 'deleted'
  end

  on Comment2Restored do |_event|
    @status = 'pending'
    @rejection_feedback = nil
  end

  on Comment2Updated do |event|
    @text = event.data.fetch(:text)
    @status = 'pending'
  end

  private

  def ensure_in_states(allowed_states)
    raise_standard_error("invalid state: #{@status}") unless allowed_states.include?(@status)
  end

  def raise_standard_error(message)
    raise StandardError, "Comment2Aggregate(#{id}): #{message}"
  end
end


