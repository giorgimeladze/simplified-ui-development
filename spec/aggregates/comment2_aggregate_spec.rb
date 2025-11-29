require 'rails_helper'

RSpec.describe Comment2Aggregate do
  let(:aggregate_id) { SecureRandom.uuid }
  let(:aggregate) { Comment2Aggregate.new(aggregate_id) }
  let(:user) { create(:user, role: :viewer) }
  let(:article2_id) { SecureRandom.uuid }

  describe '#initialize' do
    it 'sets the id' do
      expect(aggregate.id).to eq(aggregate_id)
    end

    it 'initializes with unknown status' do
      expect(aggregate.status).to eq('unknown')
    end
  end

  describe '#create' do
    let(:text) { 'Test comment' }

    it 'applies Comment2Created event' do
      expect {
        aggregate.create(text: text, article2_id: article2_id, author_id: user.id)
      }.to change { aggregate.unpublished_events.count }.by(1)

      event = aggregate.unpublished_events.to_a.last
      expect(event).to be_a(Comment2Created)
      expect(event.data[:comment2_id]).to eq(aggregate_id)
      expect(event.data[:text]).to eq(text)
      expect(event.data[:article2_id]).to eq(article2_id)
      expect(event.data[:user_id]).to eq(user.id)
    end

    it 'raises error if already created' do
      aggregate.create(text: text, article2_id: article2_id, author_id: user.id)
      aggregate.instance_variable_get(:@unpublished_events).clear

      expect {
        aggregate.create(text: text, article2_id: article2_id, author_id: user.id)
      }.to raise_error(StandardError, /already created/)
    end

    context 'when Comment2Created event is applied' do
      it 'sets text, article2_id, author_id, and status' do
        event = Comment2Created.new(data: {
          comment2_id: aggregate_id,
          text: text,
          article2_id: article2_id,
          user_id: user.id
        })
        aggregate.apply(event)

        expect(aggregate.text).to eq(text)
        expect(aggregate.article2_id).to eq(article2_id)
        expect(aggregate.author_id).to eq(user.id)
        expect(aggregate.status).to eq('pending')
        expect(aggregate.rejection_feedback).to be_nil
      end
    end
  end

  describe '#approve' do
    before do
      aggregate.create(text: 'Test', article2_id: article2_id, author_id: user.id)
      aggregate.instance_variable_get(:@unpublished_events).clear
    end

    it 'applies Comment2Approved event' do
      expect {
        aggregate.approve(actor_id: user.id)
      }.to change { aggregate.unpublished_events.count }.by(1)

      event = aggregate.unpublished_events.to_a.last
      expect(event).to be_a(Comment2Approved)
      expect(event.data[:comment2_id]).to eq(aggregate_id)
      expect(event.data[:user_id]).to eq(user.id)
    end

    it 'raises error if not in pending state' do
      aggregate.apply(Comment2Approved.new(data: { comment2_id: aggregate_id, user_id: user.id }))
      aggregate.instance_variable_get(:@unpublished_events).clear

      expect {
        aggregate.approve(actor_id: user.id)
      }.to raise_error(StandardError, /invalid state/)
    end

    context 'when Comment2Approved event is applied' do
      it 'changes status to approved' do
        event = Comment2Approved.new(data: { comment2_id: aggregate_id, user_id: user.id })
        aggregate.apply(event)

        expect(aggregate.status).to eq('approved')
      end
    end
  end

  describe '#reject' do
    before do
      aggregate.create(text: 'Test', article2_id: article2_id, author_id: user.id)
      aggregate.instance_variable_get(:@unpublished_events).clear
    end

    it 'applies Comment2Rejected event' do
      feedback = 'Inappropriate content'
      expect {
        aggregate.reject(rejection_feedback: feedback, actor_id: user.id)
      }.to change { aggregate.unpublished_events.count }.by(1)

      event = aggregate.unpublished_events.to_a.last
      expect(event).to be_a(Comment2Rejected)
      expect(event.data[:comment2_id]).to eq(aggregate_id)
      expect(event.data[:rejection_feedback]).to eq(feedback)
      expect(event.data[:user_id]).to eq(user.id)
    end

    it 'raises error if not in pending state' do
      aggregate.apply(Comment2Approved.new(data: { comment2_id: aggregate_id, user_id: user.id }))
      aggregate.instance_variable_get(:@unpublished_events).clear

      expect {
        aggregate.reject(rejection_feedback: 'Feedback', actor_id: user.id)
      }.to raise_error(StandardError, /invalid state/)
    end

    context 'when Comment2Rejected event is applied' do
      it 'changes status to rejected and sets rejection_feedback' do
        feedback = 'Not appropriate'
        event = Comment2Rejected.new(data: {
          comment2_id: aggregate_id,
          rejection_feedback: feedback,
          user_id: user.id
        })
        aggregate.apply(event)

        expect(aggregate.status).to eq('rejected')
        expect(aggregate.rejection_feedback).to eq(feedback)
      end
    end
  end

  describe '#delete' do
    before do
      aggregate.create(text: 'Test', article2_id: article2_id, author_id: user.id)
      aggregate.instance_variable_get(:@unpublished_events).clear
    end

    it 'applies Comment2Deleted event from pending state' do
      expect {
        aggregate.delete(actor_id: user.id)
      }.to change { aggregate.unpublished_events.count }.by(1)

      event = aggregate.unpublished_events.to_a.last
      expect(event).to be_a(Comment2Deleted)
      expect(event.data[:comment2_id]).to eq(aggregate_id)
      expect(event.data[:user_id]).to eq(user.id)
    end

    it 'applies Comment2Deleted event from approved state' do
      aggregate.apply(Comment2Approved.new(data: { comment2_id: aggregate_id, user_id: user.id }))
      aggregate.instance_variable_get(:@unpublished_events).clear

      expect {
        aggregate.delete(actor_id: user.id)
      }.to change { aggregate.unpublished_events.count }.by(1)
    end

    it 'applies Comment2Deleted event from rejected state' do
      aggregate.apply(Comment2Rejected.new(data: {
        comment2_id: aggregate_id,
        rejection_feedback: 'Feedback',
        user_id: user.id
      }))
      aggregate.instance_variable_get(:@unpublished_events).clear

      expect {
        aggregate.delete(actor_id: user.id)
      }.to change { aggregate.unpublished_events.count }.by(1)
    end

    it 'raises error if not in allowed state' do
      aggregate.apply(Comment2Deleted.new(data: { comment2_id: aggregate_id, user_id: user.id }))
      aggregate.instance_variable_get(:@unpublished_events).clear

      expect {
        aggregate.delete(actor_id: user.id)
      }.to raise_error(StandardError, /invalid state/)
    end

    context 'when Comment2Deleted event is applied' do
      it 'changes status to deleted' do
        event = Comment2Deleted.new(data: { comment2_id: aggregate_id, user_id: user.id })
        aggregate.apply(event)

        expect(aggregate.status).to eq('deleted')
      end
    end
  end

  describe '#restore' do
    before do
      aggregate.create(text: 'Test', article2_id: article2_id, author_id: user.id)
      aggregate.apply(Comment2Deleted.new(data: { comment2_id: aggregate_id, user_id: user.id }))
      aggregate.instance_variable_get(:@unpublished_events).clear
    end

    it 'applies Comment2Restored event' do
      expect {
        aggregate.restore(actor_id: user.id)
      }.to change { aggregate.unpublished_events.count }.by(1)

      event = aggregate.unpublished_events.to_a.last
      expect(event).to be_a(Comment2Restored)
      expect(event.data[:comment2_id]).to eq(aggregate_id)
      expect(event.data[:user_id]).to eq(user.id)
    end

    it 'raises error if not in deleted state' do
      aggregate.apply(Comment2Restored.new(data: { comment2_id: aggregate_id, user_id: user.id }))
      aggregate.instance_variable_get(:@unpublished_events).clear

      expect {
        aggregate.restore(actor_id: user.id)
      }.to raise_error(StandardError, /invalid state/)
    end

    context 'when Comment2Restored event is applied' do
      it 'changes status to pending and clears rejection_feedback' do
        aggregate.instance_variable_set(:@rejection_feedback, 'Some feedback')
        event = Comment2Restored.new(data: { comment2_id: aggregate_id, user_id: user.id })
        aggregate.apply(event)

        expect(aggregate.status).to eq('pending')
        expect(aggregate.rejection_feedback).to be_nil
      end
    end
  end

  describe '#update' do
    before do
      aggregate.create(text: 'Original', article2_id: article2_id, author_id: user.id)
      aggregate.apply(Comment2Rejected.new(data: {
        comment2_id: aggregate_id,
        rejection_feedback: 'Feedback',
        user_id: user.id
      }))
      aggregate.instance_variable_get(:@unpublished_events).clear
    end

    it 'applies Comment2Updated event' do
      new_text = 'Updated comment text'
      expect {
        aggregate.update(text: new_text, actor_id: user.id)
      }.to change { aggregate.unpublished_events.count }.by(1)

      event = aggregate.unpublished_events.to_a.last
      expect(event).to be_a(Comment2Updated)
      expect(event.data[:comment2_id]).to eq(aggregate_id)
      expect(event.data[:text]).to eq(new_text)
      expect(event.data[:user_id]).to eq(user.id)
    end

    it 'raises error if not in rejected state' do
      aggregate.apply(Comment2Updated.new(data: {
        comment2_id: aggregate_id,
        text: 'Updated',
        user_id: user.id
      }))
      aggregate.instance_variable_get(:@unpublished_events).clear

      expect {
        aggregate.update(text: 'New text', actor_id: user.id)
      }.to raise_error(StandardError, /invalid state/)
    end

    context 'when Comment2Updated event is applied' do
      it 'updates text and changes status to pending' do
        event = Comment2Updated.new(data: {
          comment2_id: aggregate_id,
          text: 'Updated text',
          user_id: user.id
        })
        aggregate.apply(event)

        expect(aggregate.text).to eq('Updated text')
        expect(aggregate.status).to eq('pending')
      end
    end
  end
end

