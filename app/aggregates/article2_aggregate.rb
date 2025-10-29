class Article2Aggregate
  include AggregateRoot

  attr_reader :id, :title, :content, :author_id, :status, :rejection_feedback

  def initialize(id)
    @id = id
    @status = 'unknown'
  end

  def create(title:, content:, author_id:)
    raise_standard_error('already created') unless @status == 'unknown'
    apply Article2Created.new(data: {
      article2_id: id,
      title: title,
      content: content,
      user_id: author_id
    })
  end

  def update(title:, content:, actor_id:)
    ensure_in_states(%w[draft rejected])
    apply Article2Updated.new(data: {
      article2_id: id,
      title: title,
      content: content,
      user_id: actor_id
    })
  end

  def submit(actor_id:)
    ensure_in_states(%w[draft rejected])
    apply Article2Submitted.new(data: {
      article2_id: id,
      user_id: actor_id
    })
  end

  def reject(rejection_feedback:, actor_id:)
    ensure_in_states(%w[review])
    apply Article2Rejected.new(data: {
      article2_id: id,
      rejection_feedback: rejection_feedback,
      user_id: actor_id
    })
  end

  def approve_private(actor_id:)
    ensure_in_states(%w[review])
    apply Article2ApprovedPrivate.new(data: {
      article2_id: id,
      user_id: actor_id
    })
  end

  def publish(actor_id:)
    ensure_in_states(%w[review])
    apply Article2Published.new(data: {
      article2_id: id,
      user_id: actor_id
    })
  end

  def archive(actor_id:)
    ensure_in_states(%w[rejected published privated])
    apply Article2Archived.new(data: {
      article2_id: id,
      user_id: actor_id
    })
  end

  on Article2Created do |event|
    @title = event.data.fetch(:title)
    @content = event.data.fetch(:content)
    @author_id = event.data.fetch(:user_id)
    @status = 'draft'
    @rejection_feedback = nil
  end

  on Article2Updated do |event|
    @title = event.data.fetch(:title)
    @content = event.data.fetch(:content)
  end

  on Article2Submitted do |_event|
    @status = 'review'
    @rejection_feedback = nil
  end

  on Article2Rejected do |event|
    @status = 'rejected'
    @rejection_feedback = event.data.fetch(:rejection_feedback)
  end

  on Article2ApprovedPrivate do |_event|
    @status = 'privated'
  end

  on Article2Published do |_event|
    @status = 'published'
  end

  on Article2Archived do |_event|
    @status = 'archived'
  end

  private

  def ensure_in_states(allowed_states)
    raise_standard_error("invalid state: #{@status}") unless allowed_states.include?(@status)
  end

  def raise_standard_error(message)
    raise StandardError, "Article2Aggregate(#{id}): #{message}"
  end
end


