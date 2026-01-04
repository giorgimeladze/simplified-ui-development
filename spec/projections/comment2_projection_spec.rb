# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Comment2Projection do
  let(:comment2_id) { SecureRandom.uuid }
  let(:article2_id) { SecureRandom.uuid }
  let(:user) { create(:user, role: :viewer) }

  describe '.apply' do
    describe 'Comment2Created event' do
      let(:event) do
        Comment2Created.new(data: {
                              comment2_id: comment2_id,
                              text: 'Test comment',
                              article2_id: article2_id,
                              user_id: user.id
                            })
      end

      it 'creates a Comment2ReadModel' do
        expect do
          Comment2Projection.apply(event)
        end.to change(Comment2ReadModel, :count).by(1)
      end

      it 'sets correct attributes' do
        Comment2Projection.apply(event)
        comment2 = Comment2ReadModel.find(comment2_id)

        expect(comment2.id).to eq(comment2_id)
        expect(comment2.text).to eq('Test comment')
        expect(comment2.article2_id).to eq(article2_id)
        expect(comment2.author_id).to eq(user.id)
        expect(comment2.state).to eq('pending')
      end
    end

    describe 'Comment2Approved event' do
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

      it 'updates state to approved' do
        Comment2Projection.apply(event)
        comment2 = Comment2ReadModel.find(comment2_id)

        expect(comment2.state).to eq('approved')
      end
    end

    describe 'Comment2Rejected event' do
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

      it 'updates state to rejected and sets rejection_feedback' do
        Comment2Projection.apply(event)
        comment2 = Comment2ReadModel.find(comment2_id)

        expect(comment2.state).to eq('rejected')
        expect(comment2.rejection_feedback).to eq('Inappropriate')
      end
    end

    describe 'Comment2Deleted event' do
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

      it 'updates state to deleted' do
        Comment2Projection.apply(event)
        comment2 = Comment2ReadModel.find(comment2_id)

        expect(comment2.state).to eq('deleted')
      end
    end

    describe 'Comment2Restored event' do
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

      it 'updates state to pending' do
        Comment2Projection.apply(event)
        comment2 = Comment2ReadModel.find(comment2_id)

        expect(comment2.state).to eq('pending')
      end
    end

    describe 'Comment2Updated event' do
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

      it 'updates text and state to pending' do
        Comment2Projection.apply(event)
        comment2 = Comment2ReadModel.find(comment2_id)

        expect(comment2.text).to eq('Updated comment')
        expect(comment2.state).to eq('pending')
      end
    end
  end

  describe '.upsert_created' do
    it 'creates a new Comment2ReadModel' do
      event = Comment2Created.new(data: {
                                    comment2_id: comment2_id,
                                    text: 'Test comment',
                                    article2_id: article2_id,
                                    user_id: user.id
                                  })

      expect do
        Comment2Projection.upsert_created(event)
      end.to change(Comment2ReadModel, :count).by(1)
    end

    it 'updates existing Comment2ReadModel if it exists' do
      Comment2ReadModel.create!(
        id: comment2_id,
        text: 'Original',
        article2_id: article2_id,
        author_id: user.id,
        state: 'pending'
      )

      event = Comment2Created.new(data: {
                                    comment2_id: comment2_id,
                                    text: 'Updated',
                                    article2_id: article2_id,
                                    user_id: user.id
                                  })

      expect do
        Comment2Projection.upsert_created(event)
      end.not_to change(Comment2ReadModel, :count)

      comment2 = Comment2ReadModel.find(comment2_id)
      expect(comment2.text).to eq('Updated')
    end
  end

  describe '.upsert_updated' do
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

    it 'updates text and state' do
      Comment2Projection.upsert_updated(event)
      comment2 = Comment2ReadModel.find(comment2_id)

      expect(comment2.text).to eq('Updated comment')
      expect(comment2.state).to eq('pending')
    end
  end

  describe '.upsert_rejected' do
    let(:event) do
      Comment2Rejected.new(data: {
                             comment2_id: comment2_id,
                             rejection_feedback: 'Feedback',
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

    it 'updates state and rejection_feedback' do
      Comment2Projection.upsert_rejected(event)
      comment2 = Comment2ReadModel.find(comment2_id)

      expect(comment2.state).to eq('rejected')
      expect(comment2.rejection_feedback).to eq('Feedback')
    end
  end

  describe '.upsert_state' do
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

    it 'updates the state' do
      Comment2Projection.upsert_state(event, 'approved')
      comment2 = Comment2ReadModel.find(comment2_id)

      expect(comment2.state).to eq('approved')
    end
  end
end
