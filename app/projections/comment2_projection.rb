class Comment2Projection
  def self.build
    RubyEventStore::Projection
      .from_all
      .when(Comment2Created) { |_state, event| upsert_created(event) }
      .when(Comment2Approved) { |_state, event| upsert_state(event, 'approved') }
      .when(Comment2Rejected) { |_state, event| upsert_rejected(event) }
      .when(Comment2Deleted) { |_state, event| upsert_state(event, 'deleted') }
      .when(Comment2Restored) { |_state, event| upsert_state(event, 'pending') }
      .when(Comment2Updated) { |_state, event| upsert_updated(event) }
  end

  def self.apply(event)
    case event
    when Comment2Created then upsert_created(event)
    when Comment2Approved then upsert_state(event, 'approved')
    when Comment2Rejected then upsert_rejected(event)
    when Comment2Deleted then upsert_state(event, 'deleted')
    when Comment2Restored then upsert_state(event, 'pending')
    when Comment2Updated then upsert_updated(event)
    end
  end

  def self.upsert_created(event)
    id = event.data[:comment2_id]
    Comment2ReadModel.upsert({
      id: id,
      text: event.data[:text],
      article2_id: event.data[:article2_id],
      author_id: event.data[:user_id],
      state: 'pending'
    }, unique_by: :id)
  end

  def self.upsert_updated(event)
    id = event.data[:comment2_id]
    Comment2ReadModel.upsert({
      id: id,
      text: event.data[:text],
      state: 'pending'
    }, unique_by: :id)
  end

  def self.upsert_rejected(event)
    id = event.data[:comment2_id]
    Comment2ReadModel.upsert({
      id: id,
      state: 'rejected',
      rejection_feedback: event.data[:rejection_feedback]
    }, unique_by: :id)
  end

  def self.upsert_state(event, state)
    id = event.data[:comment2_id]
    Comment2ReadModel.upsert({ id: id, state: state }, unique_by: :id)
  end
end


