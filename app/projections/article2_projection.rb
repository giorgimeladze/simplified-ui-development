class Article2Projection
  def self.build
    RubyEventStore::Projection
      .from_all
      .when(Article2Created) { |_state, event| upsert_created(event) }
      .when(Article2Updated) { |_state, event| upsert_updated(event) }
      .when(Article2Submitted) { |_state, event| upsert_state(event, 'review') }
      .when(Article2Rejected) { |_state, event| upsert_rejected(event) }
      .when(Article2ApprovedPrivate) { |_state, event| upsert_state(event, 'privated') }
      .when(Article2Published) { |_state, event| upsert_state(event, 'published') }
      .when(Article2Archived) { |_state, event| upsert_state(event, 'archived') }
  end

  def self.apply(event)
    case event
    when Article2Created then upsert_created(event)
    when Article2Updated then upsert_updated(event)
    when Article2Submitted then upsert_state(event, 'review')
    when Article2Rejected then upsert_rejected(event)
    when Article2ApprovedPrivate then upsert_state(event, 'privated')
    when Article2Published then upsert_state(event, 'published')
    when Article2Archived then upsert_state(event, 'archived')
    end
  end

  def self.upsert_created(event)
    id = event.data[:article2_id]
    Article2ReadModel.upsert({
      id: id,
      title: event.data[:title],
      content: event.data[:content],
      author_id: event.data[:user_id],
      state: 'draft'
    }, unique_by: :id)
  end

  def self.upsert_updated(event)
    id = event.data[:article2_id]
    Article2ReadModel.upsert({
      id: id,
      title: event.data[:title],
      content: event.data[:content]
    }, unique_by: :id)
  end

  def self.upsert_rejected(event)
    id = event.data[:article2_id]
    Article2ReadModel.upsert({
      id: id,
      state: 'rejected',
      rejection_feedback: event.data[:rejection_feedback]
    }, unique_by: :id)
  end

  def self.upsert_state(event, state)
    id = event.data[:article2_id]
    Article2ReadModel.upsert({ id: id, state: state }, unique_by: :id)
  end
end


