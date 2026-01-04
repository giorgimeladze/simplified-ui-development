# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Article2Projection do
  let(:article2_id) { SecureRandom.uuid }
  let(:user) { create(:user, role: :editor) }

  describe '.apply' do
    describe 'Article2Created event' do
      let(:event) do
        Article2Created.new(data: {
                              article2_id: article2_id,
                              title: 'Test Article',
                              content: 'Test content',
                              user_id: user.id
                            })
      end

      it 'creates an Article2ReadModel' do
        expect do
          Article2Projection.apply(event)
        end.to change(Article2ReadModel, :count).by(1)
      end

      it 'sets correct attributes' do
        Article2Projection.apply(event)
        article2 = Article2ReadModel.find(article2_id)

        expect(article2.id).to eq(article2_id)
        expect(article2.title).to eq('Test Article')
        expect(article2.content).to eq('Test content')
        expect(article2.author_id).to eq(user.id)
        expect(article2.state).to eq('draft')
      end
    end

    describe 'Article2Updated event' do
      let(:event) do
        Article2Updated.new(data: {
                              article2_id: article2_id,
                              title: 'Updated Title',
                              content: 'Updated content',
                              user_id: user.id
                            })
      end

      before do
        Article2ReadModel.create!(
          id: article2_id,
          title: 'Original Title',
          content: 'Original content',
          author_id: user.id,
          state: 'draft'
        )
      end

      it 'updates the Article2ReadModel' do
        Article2Projection.apply(event)
        article2 = Article2ReadModel.find(article2_id)

        expect(article2.title).to eq('Updated Title')
        expect(article2.content).to eq('Updated content')
      end

      it 'does not change other attributes' do
        original_state = Article2ReadModel.find(article2_id).state
        Article2Projection.apply(event)
        article2 = Article2ReadModel.find(article2_id)

        expect(article2.state).to eq(original_state)
        expect(article2.author_id).to eq(user.id)
      end
    end

    describe 'Article2Submitted event' do
      let(:event) do
        Article2Submitted.new(data: {
                                article2_id: article2_id,
                                user_id: user.id
                              })
      end

      before do
        Article2ReadModel.create!(
          id: article2_id,
          title: 'Test Article',
          content: 'Content',
          author_id: user.id,
          state: 'draft'
        )
      end

      it 'updates state to review' do
        Article2Projection.apply(event)
        article2 = Article2ReadModel.find(article2_id)

        expect(article2.state).to eq('review')
      end
    end

    describe 'Article2Rejected event' do
      let(:event) do
        Article2Rejected.new(data: {
                               article2_id: article2_id,
                               rejection_feedback: 'Needs improvement',
                               user_id: user.id
                             })
      end

      before do
        Article2ReadModel.create!(
          id: article2_id,
          title: 'Test Article',
          content: 'Content',
          author_id: user.id,
          state: 'review'
        )
      end

      it 'updates state to rejected and sets rejection_feedback' do
        Article2Projection.apply(event)
        article2 = Article2ReadModel.find(article2_id)

        expect(article2.state).to eq('rejected')
        expect(article2.rejection_feedback).to eq('Needs improvement')
      end
    end

    describe 'Article2ApprovedPrivate event' do
      let(:event) do
        Article2ApprovedPrivate.new(data: {
                                      article2_id: article2_id,
                                      user_id: user.id
                                    })
      end

      before do
        Article2ReadModel.create!(
          id: article2_id,
          title: 'Test Article',
          content: 'Content',
          author_id: user.id,
          state: 'review'
        )
      end

      it 'updates state to privated' do
        Article2Projection.apply(event)
        article2 = Article2ReadModel.find(article2_id)

        expect(article2.state).to eq('privated')
      end
    end

    describe 'Article2Published event' do
      let(:event) do
        Article2Published.new(data: {
                                article2_id: article2_id,
                                user_id: user.id
                              })
      end

      before do
        Article2ReadModel.create!(
          id: article2_id,
          title: 'Test Article',
          content: 'Content',
          author_id: user.id,
          state: 'review'
        )
      end

      it 'updates state to published' do
        Article2Projection.apply(event)
        article2 = Article2ReadModel.find(article2_id)

        expect(article2.state).to eq('published')
      end
    end

    describe 'Article2Archived event' do
      let(:event) do
        Article2Archived.new(data: {
                               article2_id: article2_id,
                               user_id: user.id
                             })
      end

      before do
        Article2ReadModel.create!(
          id: article2_id,
          title: 'Test Article',
          content: 'Content',
          author_id: user.id,
          state: 'published'
        )
      end

      it 'updates state to archived' do
        Article2Projection.apply(event)
        article2 = Article2ReadModel.find(article2_id)

        expect(article2.state).to eq('archived')
      end
    end
  end

  describe '.upsert_created' do
    it 'creates a new Article2ReadModel' do
      event = Article2Created.new(data: {
                                    article2_id: article2_id,
                                    title: 'Test Article',
                                    content: 'Test content',
                                    user_id: user.id
                                  })

      expect do
        Article2Projection.upsert_created(event)
      end.to change(Article2ReadModel, :count).by(1)
    end

    it 'updates existing Article2ReadModel if it exists' do
      Article2ReadModel.create!(
        id: article2_id,
        title: 'Original',
        content: 'Original content',
        author_id: user.id,
        state: 'draft'
      )

      event = Article2Created.new(data: {
                                    article2_id: article2_id,
                                    title: 'Updated',
                                    content: 'Updated content',
                                    user_id: user.id
                                  })

      expect do
        Article2Projection.upsert_created(event)
      end.not_to change(Article2ReadModel, :count)

      article2 = Article2ReadModel.find(article2_id)
      expect(article2.title).to eq('Updated')
      expect(article2.content).to eq('Updated content')
    end
  end

  describe '.upsert_updated' do
    let(:event) do
      Article2Updated.new(data: {
                            article2_id: article2_id,
                            title: 'Updated Title',
                            content: 'Updated content',
                            user_id: user.id
                          })
    end

    before do
      Article2ReadModel.create!(
        id: article2_id,
        title: 'Original Title',
        content: 'Original content',
        author_id: user.id,
        state: 'draft'
      )
    end

    it 'updates the Article2ReadModel' do
      Article2Projection.upsert_updated(event)
      article2 = Article2ReadModel.find(article2_id)

      expect(article2.title).to eq('Updated Title')
      expect(article2.content).to eq('Updated content')
    end
  end

  describe '.upsert_rejected' do
    let(:event) do
      Article2Rejected.new(data: {
                             article2_id: article2_id,
                             rejection_feedback: 'Feedback',
                             user_id: user.id
                           })
    end

    before do
      Article2ReadModel.create!(
        id: article2_id,
        title: 'Test Article',
        content: 'Content',
        author_id: user.id,
        state: 'review'
      )
    end

    it 'updates state and rejection_feedback' do
      Article2Projection.upsert_rejected(event)
      article2 = Article2ReadModel.find(article2_id)

      expect(article2.state).to eq('rejected')
      expect(article2.rejection_feedback).to eq('Feedback')
    end
  end

  describe '.upsert_state' do
    let(:event) do
      Article2Submitted.new(data: {
                              article2_id: article2_id,
                              user_id: user.id
                            })
    end

    before do
      Article2ReadModel.create!(
        id: article2_id,
        title: 'Test Article',
        content: 'Content',
        author_id: user.id,
        state: 'draft'
      )
    end

    it 'updates the state' do
      Article2Projection.upsert_state(event, 'review')
      article2 = Article2ReadModel.find(article2_id)

      expect(article2.state).to eq('review')
    end
  end
end
