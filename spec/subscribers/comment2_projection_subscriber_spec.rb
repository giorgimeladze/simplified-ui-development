# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Comment2ProjectionSubscriber do
  let(:subscriber) { Comment2ProjectionSubscriber.new }
  let(:comment2_id) { SecureRandom.uuid }
  let(:article2_id) { SecureRandom.uuid }
  let(:user) { create(:user, role: :viewer) }

  describe '#call' do
    context 'with Comment2Created event' do
      let(:event) do
        Comment2Created.new(data: {
                              comment2_id: comment2_id,
                              text: 'Test comment',
                              article2_id: article2_id,
                              user_id: user.id
                            })
      end

      it 'calls Comment2Projection.apply with the event' do
        expect(Comment2Projection).to receive(:apply).with(event)
        subscriber.call(event)
      end

      it 'creates Comment2ReadModel' do
        expect do
          subscriber.call(event)
        end.to change(Comment2ReadModel, :count).by(1)
      end
    end

    context 'with Comment2Approved event' do
      let(:event) do
        Comment2Approved.new(data: {
                               comment2_id: comment2_id,
                               user_id: user.id
                             })
      end

      before do
        Comment2ReadModel.create!(
          id: comment2_id,
          text: 'Test comment',
          article2_id: article2_id,
          author_id: user.id,
          state: 'pending'
        )
      end

      it 'calls Comment2Projection.apply with the event' do
        expect(Comment2Projection).to receive(:apply).with(event)
        subscriber.call(event)
      end

      it 'updates state to approved' do
        subscriber.call(event)
        comment2 = Comment2ReadModel.find(comment2_id)

        expect(comment2.state).to eq('approved')
      end
    end

    context 'with Comment2Rejected event' do
      let(:event) do
        Comment2Rejected.new(data: {
                               comment2_id: comment2_id,
                               rejection_feedback: 'Inappropriate',
                               user_id: user.id
                             })
      end

      before do
        Comment2ReadModel.create!(
          id: comment2_id,
          text: 'Test comment',
          article2_id: article2_id,
          author_id: user.id,
          state: 'pending'
        )
      end

      it 'calls Comment2Projection.apply with the event' do
        expect(Comment2Projection).to receive(:apply).with(event)
        subscriber.call(event)
      end

      it 'updates state to rejected' do
        subscriber.call(event)
        comment2 = Comment2ReadModel.find(comment2_id)

        expect(comment2.state).to eq('rejected')
        expect(comment2.rejection_feedback).to eq('Inappropriate')
      end
    end

    context 'with Comment2Deleted event' do
      let(:event) do
        Comment2Deleted.new(data: {
                              comment2_id: comment2_id,
                              user_id: user.id
                            })
      end

      before do
        Comment2ReadModel.create!(
          id: comment2_id,
          text: 'Test comment',
          article2_id: article2_id,
          author_id: user.id,
          state: 'approved'
        )
      end

      it 'calls Comment2Projection.apply with the event' do
        expect(Comment2Projection).to receive(:apply).with(event)
        subscriber.call(event)
      end

      it 'updates state to deleted' do
        subscriber.call(event)
        comment2 = Comment2ReadModel.find(comment2_id)

        expect(comment2.state).to eq('deleted')
      end
    end

    context 'with Comment2Restored event' do
      let(:event) do
        Comment2Restored.new(data: {
                               comment2_id: comment2_id,
                               user_id: user.id
                             })
      end

      before do
        Comment2ReadModel.create!(
          id: comment2_id,
          text: 'Test comment',
          article2_id: article2_id,
          author_id: user.id,
          state: 'deleted'
        )
      end

      it 'calls Comment2Projection.apply with the event' do
        expect(Comment2Projection).to receive(:apply).with(event)
        subscriber.call(event)
      end

      it 'updates state to pending' do
        subscriber.call(event)
        comment2 = Comment2ReadModel.find(comment2_id)

        expect(comment2.state).to eq('pending')
      end
    end

    context 'with Comment2Updated event' do
      let(:event) do
        Comment2Updated.new(data: {
                              comment2_id: comment2_id,
                              text: 'Updated comment',
                              user_id: user.id
                            })
      end

      before do
        Comment2ReadModel.create!(
          id: comment2_id,
          text: 'Original comment',
          article2_id: article2_id,
          author_id: user.id,
          state: 'rejected'
        )
      end

      it 'calls Comment2Projection.apply with the event' do
        expect(Comment2Projection).to receive(:apply).with(event)
        subscriber.call(event)
      end

      it 'updates text and state' do
        subscriber.call(event)
        comment2 = Comment2ReadModel.find(comment2_id)

        expect(comment2.text).to eq('Updated comment')
        expect(comment2.state).to eq('pending')
      end
    end
  end
end
