# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Article2ProjectionSubscriber do
  let(:subscriber) { Article2ProjectionSubscriber.new }
  let(:article2_id) { SecureRandom.uuid }
  let(:user) { create(:user, role: :editor) }

  describe '#call' do
    context 'with Article2Created event' do
      let(:event) do
        Article2Created.new(data: {
                              article2_id: article2_id,
                              title: 'Test Article',
                              content: 'Test content',
                              user_id: user.id
                            })
      end

      it 'calls Article2Projection.apply with the event' do
        expect(Article2Projection).to receive(:apply).with(event)
        subscriber.call(event)
      end

      it 'creates Article2ReadModel' do
        expect do
          subscriber.call(event)
        end.to change(Article2ReadModel, :count).by(1)
      end
    end

    context 'with Article2Updated event' do
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

      it 'calls Article2Projection.apply with the event' do
        expect(Article2Projection).to receive(:apply).with(event)
        subscriber.call(event)
      end

      it 'updates Article2ReadModel' do
        subscriber.call(event)
        article2 = Article2ReadModel.find(article2_id)

        expect(article2.title).to eq('Updated Title')
        expect(article2.content).to eq('Updated content')
      end
    end

    context 'with Article2Submitted event' do
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

      it 'calls Article2Projection.apply with the event' do
        expect(Article2Projection).to receive(:apply).with(event)
        subscriber.call(event)
      end

      it 'updates state to review' do
        subscriber.call(event)
        article2 = Article2ReadModel.find(article2_id)

        expect(article2.state).to eq('review')
      end
    end

    context 'when an error occurs' do
      let(:event) do
        Article2Created.new(data: {
                              article2_id: article2_id,
                              title: 'Test Article',
                              content: 'Test content',
                              user_id: user.id
                            })
      end

      before do
        allow(Article2Projection).to receive(:apply).and_raise(StandardError.new('Test error'))
      end

      it 'raises the error' do
        expect do
          subscriber.call(event)
        end.to raise_error(StandardError, 'Test error')
      end
    end
  end
end
