require 'rails_helper'

RSpec.describe Article2Aggregate do
  let(:aggregate_id) { SecureRandom.uuid }
  let(:aggregate) { Article2Aggregate.new(aggregate_id) }
  let(:user) { create(:user, role: :editor) }

  describe '#initialize' do
    it 'sets the id' do
      expect(aggregate.id).to eq(aggregate_id)
    end

    it 'initializes with unknown status' do
      expect(aggregate.status).to eq('unknown')
    end
  end

  describe '#create' do
    let(:title) { 'Test Article' }
    let(:content) { 'Test content' }

    it 'applies Article2Created event' do
      expect {
        aggregate.create(title: title, content: content, author_id: user.id)
      }.to change { aggregate.unpublished_events.count }.by(1)

      event = aggregate.unpublished_events.to_a.last
      expect(event).to be_a(Article2Created)
      expect(event.data[:article2_id]).to eq(aggregate_id)
      expect(event.data[:title]).to eq(title)
      expect(event.data[:content]).to eq(content)
      expect(event.data[:user_id]).to eq(user.id)
    end

    it 'raises error if already created' do
      aggregate.create(title: title, content: content, author_id: user.id)
      aggregate.instance_variable_get(:@unpublished_events).clear

      expect {
        aggregate.create(title: title, content: content, author_id: user.id)
      }.to raise_error(StandardError, /already created/)
    end

    context 'when Article2Created event is applied' do
      it 'sets title, content, and author_id' do
        event = Article2Created.new(data: {
          article2_id: aggregate_id,
          title: title,
          content: content,
          user_id: user.id
        })
        aggregate.apply(event)

        expect(aggregate.title).to eq(title)
        expect(aggregate.content).to eq(content)
        expect(aggregate.author_id).to eq(user.id)
        expect(aggregate.status).to eq('draft')
        expect(aggregate.rejection_feedback).to be_nil
      end
    end
  end

  describe '#update' do
    before do
      aggregate.create(title: 'Original', content: 'Original content', author_id: user.id)
      aggregate.instance_variable_get(:@unpublished_events).clear
    end

    it 'applies Article2Updated event' do
      new_title = 'Updated Title'
      new_content = 'Updated content'

      expect {
        aggregate.update(title: new_title, content: new_content, actor_id: user.id)
      }.to change { aggregate.unpublished_events.count }.by(1)

      event = aggregate.unpublished_events.to_a.last
      expect(event).to be_a(Article2Updated)
      expect(event.data[:article2_id]).to eq(aggregate_id)
      expect(event.data[:title]).to eq(new_title)
      expect(event.data[:content]).to eq(new_content)
      expect(event.data[:user_id]).to eq(user.id)
    end

    context 'when Article2Updated event is applied' do
      it 'updates title and content' do
        event = Article2Updated.new(data: {
          article2_id: aggregate_id,
          title: 'New Title',
          content: 'New content',
          user_id: user.id
        })
        aggregate.apply(event)

        expect(aggregate.title).to eq('New Title')
        expect(aggregate.content).to eq('New content')
      end
    end
  end

  describe '#submit' do
    before do
      aggregate.create(title: 'Test', content: 'Content', author_id: user.id)
      aggregate.instance_variable_get(:@unpublished_events).clear
    end

    it 'applies Article2Submitted event' do
      expect {
        aggregate.submit(actor_id: user.id)
      }.to change { aggregate.unpublished_events.count }.by(1)

      event = aggregate.unpublished_events.to_a.last
      expect(event).to be_a(Article2Submitted)
      expect(event.data[:article2_id]).to eq(aggregate_id)
      expect(event.data[:user_id]).to eq(user.id)
    end

    context 'when Article2Submitted event is applied' do
      it 'changes status to review and clears rejection_feedback' do
        aggregate.instance_variable_set(:@rejection_feedback, 'Some feedback')
        event = Article2Submitted.new(data: { article2_id: aggregate_id, user_id: user.id })
        aggregate.apply(event)

        expect(aggregate.status).to eq('review')
        expect(aggregate.rejection_feedback).to be_nil
      end
    end
  end

  describe '#reject' do
    before do
      aggregate.create(title: 'Test', content: 'Content', author_id: user.id)
      aggregate.apply(Article2Submitted.new(data: { article2_id: aggregate_id, user_id: user.id }))
      aggregate.instance_variable_get(:@unpublished_events).clear
    end

    it 'applies Article2Rejected event' do
      feedback = 'Needs improvement'
      expect {
        aggregate.reject(rejection_feedback: feedback, actor_id: user.id)
      }.to change { aggregate.unpublished_events.count }.by(1)

      event = aggregate.unpublished_events.to_a.last
      expect(event).to be_a(Article2Rejected)
      expect(event.data[:article2_id]).to eq(aggregate_id)
      expect(event.data[:rejection_feedback]).to eq(feedback)
      expect(event.data[:user_id]).to eq(user.id)
    end

    context 'when Article2Rejected event is applied' do
      it 'changes status to rejected and sets rejection_feedback' do
        feedback = 'Not good enough'
        event = Article2Rejected.new(data: {
          article2_id: aggregate_id,
          rejection_feedback: feedback,
          user_id: user.id
        })
        aggregate.apply(event)

        expect(aggregate.status).to eq('rejected')
        expect(aggregate.rejection_feedback).to eq(feedback)
      end
    end
  end

  describe '#approve_private' do
    before do
      aggregate.create(title: 'Test', content: 'Content', author_id: user.id)
      aggregate.apply(Article2Submitted.new(data: { article2_id: aggregate_id, user_id: user.id }))
      aggregate.instance_variable_get(:@unpublished_events).clear
    end

    it 'applies Article2ApprovedPrivate event' do
      expect {
        aggregate.approve_private(actor_id: user.id)
      }.to change { aggregate.unpublished_events.count }.by(1)

      event = aggregate.unpublished_events.to_a.last
      expect(event).to be_a(Article2ApprovedPrivate)
      expect(event.data[:article2_id]).to eq(aggregate_id)
      expect(event.data[:user_id]).to eq(user.id)
    end

    context 'when Article2ApprovedPrivate event is applied' do
      it 'changes status to privated' do
        event = Article2ApprovedPrivate.new(data: { article2_id: aggregate_id, user_id: user.id })
        aggregate.apply(event)

        expect(aggregate.status).to eq('privated')
      end
    end
  end

  describe '#publish' do
    before do
      aggregate.create(title: 'Test', content: 'Content', author_id: user.id)
      aggregate.apply(Article2Submitted.new(data: { article2_id: aggregate_id, user_id: user.id }))
      aggregate.instance_variable_get(:@unpublished_events).clear
    end

    it 'applies Article2Published event' do
      expect {
        aggregate.publish(actor_id: user.id)
      }.to change { aggregate.unpublished_events.count }.by(1)

      event = aggregate.unpublished_events.to_a.last
      expect(event).to be_a(Article2Published)
      expect(event.data[:article2_id]).to eq(aggregate_id)
      expect(event.data[:user_id]).to eq(user.id)
    end

    context 'when Article2Published event is applied' do
      it 'changes status to published' do
        event = Article2Published.new(data: { article2_id: aggregate_id, user_id: user.id })
        aggregate.apply(event)

        expect(aggregate.status).to eq('published')
      end
    end
  end

  describe '#archive' do
    before do
      aggregate.create(title: 'Test', content: 'Content', author_id: user.id)
    end

    context 'from rejected state' do
      before do
        aggregate.apply(Article2Submitted.new(data: { article2_id: aggregate_id, user_id: user.id }))
        aggregate.apply(Article2Rejected.new(data: {
          article2_id: aggregate_id,
          rejection_feedback: 'Feedback',
          user_id: user.id
        }))
        aggregate.instance_variable_get(:@unpublished_events).clear
      end

      it 'applies Article2Archived event' do
        expect {
          aggregate.archive(actor_id: user.id)
        }.to change { aggregate.unpublished_events.count }.by(1)

        event = aggregate.unpublished_events.to_a.last
        expect(event).to be_a(Article2Archived)
      end

      it 'changes status to archived when event is applied' do
        event = Article2Archived.new(data: { article2_id: aggregate_id, user_id: user.id })
        aggregate.apply(event)

        expect(aggregate.status).to eq('archived')
      end
    end

    context 'from published state' do
      before do
        aggregate.apply(Article2Submitted.new(data: { article2_id: aggregate_id, user_id: user.id }))
        aggregate.apply(Article2Published.new(data: { article2_id: aggregate_id, user_id: user.id }))
        aggregate.instance_variable_get(:@unpublished_events).clear
      end

      it 'applies Article2Archived event' do
        expect {
          aggregate.archive(actor_id: user.id)
        }.to change { aggregate.unpublished_events.count }.by(1)
      end
    end

    context 'from privated state' do
      before do
        aggregate.apply(Article2Submitted.new(data: { article2_id: aggregate_id, user_id: user.id }))
        aggregate.apply(Article2ApprovedPrivate.new(data: { article2_id: aggregate_id, user_id: user.id }))
        aggregate.instance_variable_get(:@unpublished_events).clear
      end

      it 'applies Article2Archived event' do
        expect {
          aggregate.archive(actor_id: user.id)
        }.to change { aggregate.unpublished_events.count }.by(1)
      end
    end
  end
end

