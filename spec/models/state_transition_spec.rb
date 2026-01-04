# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StateTransition, type: :model do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }

  describe 'associations' do
    it 'belongs to transitionable' do
      article.submit!
      transition = StateTransition.last
      expect(transition).to respond_to(:transitionable)
      expect(transition.transitionable).to eq(article)
    end

    it 'belongs to user' do
      article.submit!
      transition = StateTransition.last
      expect(transition).to respond_to(:user)
      expect(transition.user).to eq(user)
    end
  end

  describe 'creating state transitions' do
    it 'creates a state transition through article state change' do
      expect do
        article.submit!
      end.to change(StateTransition, :count).by(1)
    end

    it 'stores correct transition data' do
      article.submit!
      transition = StateTransition.last

      expect(transition.transitionable).to eq(article)
      expect(transition.from_state).to eq('draft')
      expect(transition.to_state).to eq('review')
      expect(transition.event).to eq('submit!')
      expect(transition.user).to eq(user)
    end

    it 'creates state transition for comment state change' do
      comment = create(:comment, article: article, user: user)

      expect do
        comment.approve!
      end.to change(StateTransition, :count).by(1)

      transition = StateTransition.last
      expect(transition.transitionable).to eq(comment)
      expect(transition.from_state).to eq('pending')
      expect(transition.to_state).to eq('approved')
      expect(transition.event).to eq('approve!')
    end
  end

  describe '.transitions_by_event' do
    let!(:transition1) do
      article.submit!
      StateTransition.last
    end
    let!(:transition2) do
      article.publish!
      StateTransition.last
    end
    let!(:transition3) do
      comment = create(:comment, article: article, user: user)
      comment.approve!
      StateTransition.last
    end

    it 'groups transitions by event name' do
      result = StateTransition.transitions_by_event
      expect(result).to be_a(Hash)
      expect(result.keys).to include('submit!', 'publish!', 'approve!')
    end

    it 'counts transitions per event' do
      result = StateTransition.transitions_by_event
      expect(result['submit!']).to eq(1)
      expect(result['publish!']).to eq(1)
      expect(result['approve!']).to eq(1)
    end
  end

  describe 'polymorphic association' do
    it 'can belong to Article' do
      article.submit!
      transition = StateTransition.last
      expect(transition.transitionable_type).to eq('Article')
      expect(transition.transitionable_id).to eq(article.id)
    end

    it 'can belong to Comment' do
      comment = create(:comment, article: article, user: user)
      comment.approve!
      transition = StateTransition.last
      expect(transition.transitionable_type).to eq('Comment')
      expect(transition.transitionable_id).to eq(comment.id)
    end
  end
end
