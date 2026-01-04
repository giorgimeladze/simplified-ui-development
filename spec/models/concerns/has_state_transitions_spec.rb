# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HasStateTransitions, type: :model do
  # Test using Article model which includes HasStateTransitions
  let(:user) { create(:user, role: :editor) }
  let(:article) { create(:article, user: user) }

  describe 'included in models' do
    it 'is included in Article' do
      expect(Article.included_modules).to include(HasStateTransitions)
    end

    it 'is included in Comment' do
      expect(Comment.included_modules).to include(HasStateTransitions)
    end
  end

  describe 'associations' do
    it 'adds state_transitions association to Article' do
      expect(article).to respond_to(:state_transitions)
    end
  end

  describe 'state transition logging' do
    it 'creates a state transition record after state change' do
      expect do
        article.submit!
      end.to change(StateTransition, :count).by(1)
    end

    it 'logs correct transition data' do
      article.submit!
      transition = StateTransition.last

      expect(transition.transitionable).to eq(article)
      expect(transition.from_state).to eq('draft')
      expect(transition.to_state).to eq('review')
      expect(transition.event).to eq('submit!')
      expect(transition.user).to eq(user)
    end

    it 'logs multiple transitions correctly' do
      article.submit!
      article.publish!

      transitions = article.state_transitions.order(:created_at)
      expect(transitions.count).to eq(2)

      expect(transitions.first.from_state).to eq('draft')
      expect(transitions.first.to_state).to eq('review')
      expect(transitions.first.event).to eq('submit!')

      expect(transitions.last.from_state).to eq('review')
      expect(transitions.last.to_state).to eq('published')
      expect(transitions.last.event).to eq('publish!')
    end

    it 'handles errors gracefully' do
      # Mock StateTransition.create! to raise an error
      allow(StateTransition).to receive(:create!).and_raise(StandardError.new('Test error'))

      expect do
        article.submit!
      end.not_to raise_error
    end
  end

  describe 'comment state transitions' do
    let(:comment) { create(:comment, article: article, user: user) }

    it 'logs comment state transitions' do
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

  describe 'callback behavior' do
    it 'only logs after successful commit' do
      # Start a transaction
      ActiveRecord::Base.transaction do
        article.submit!
        # Transition should not be logged yet
        expect(StateTransition.count).to eq(0)
      end
      # After commit, transition should be logged
      expect(StateTransition.count).to eq(1)
    end
  end
end
