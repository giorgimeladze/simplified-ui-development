# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Comment, type: :model do
  let(:user) { create(:user, role: :viewer) }
  let(:article) { create(:article, user: user) }
  let(:comment) { create(:comment, article: article, user: user, status: 'pending') }

  describe 'associations' do
    it 'belongs to article' do
      expect(comment).to respond_to(:article)
      expect(comment.article).to eq(article)
    end

    it 'belongs to user' do
      expect(comment).to respond_to(:user)
      expect(comment.user).to eq(user)
    end

    it 'has many state transitions' do
      expect(comment).to respond_to(:state_transitions)
    end
  end

  describe 'validations' do
    it 'requires text' do
      comment = Comment.new(article: article, user: user)
      expect(comment).not_to be_valid
      expect(comment.errors[:text]).to be_present
    end

    it 'requires user' do
      comment = Comment.new(article: article, text: 'Test')
      expect(comment).not_to be_valid
      expect(comment.errors[:user]).to be_present
    end

    it 'requires article' do
      comment = Comment.new(user: user, text: 'Test')
      expect(comment).not_to be_valid
      expect(comment.errors[:article]).to be_present
    end

    it 'validates text length is at least 1' do
      comment.text = ''
      expect(comment).not_to be_valid
      expect(comment.errors[:text]).to be_present
    end

    it 'validates text length is at most 250' do
      comment.text = 'a' * 251
      expect(comment).not_to be_valid
      expect(comment.errors[:text]).to be_present
    end

    it 'validates rejection_feedback length' do
      comment.rejection_feedback = 'a' * 1001
      expect(comment).not_to be_valid
      expect(comment.errors[:rejection_feedback]).to be_present
    end

    it 'allows blank rejection_feedback' do
      comment.rejection_feedback = ''
      expect(comment).to be_valid
    end
  end

  describe 'AASM state machine' do
    describe 'initial state' do
      it 'starts in pending state' do
        new_comment = create(:comment, article: article, user: user)
        expect(new_comment.status).to eq('pending')
      end
    end

    describe 'state transitions' do
      it 'transitions from pending to approved on approve' do
        comment.approve!
        expect(comment.status).to eq('approved')
      end

      it 'transitions from pending to rejected on reject' do
        comment.reject!
        expect(comment.status).to eq('rejected')
      end

      it 'transitions from pending to deleted on delete' do
        comment.delete!
        expect(comment.status).to eq('deleted')
      end

      it 'transitions from approved to deleted on delete' do
        comment.approve!
        comment.delete!
        expect(comment.status).to eq('deleted')
      end

      it 'transitions from rejected to deleted on delete' do
        comment.reject!
        comment.delete!
        expect(comment.status).to eq('deleted')
      end

      it 'transitions from deleted to pending on restore' do
        comment.delete!
        comment.restore!
        expect(comment.status).to eq('pending')
      end

      it 'transitions from rejected to pending on resubmit' do
        comment.reject!
        comment.resubmit!
        expect(comment.status).to eq('pending')
      end
    end

    describe 'invalid transitions' do
      it 'cannot transition from approved to rejected' do
        comment.approve!
        expect { comment.reject! }.to raise_error(AASM::InvalidTransition)
      end

      it 'cannot transition from approved to pending' do
        comment.approve!
        expect { comment.resubmit! }.to raise_error(AASM::InvalidTransition)
      end
    end
  end

  describe 'scopes' do
    let!(:approved_comment) { create(:comment, article: article, user: user, status: 'approved') }
    let!(:pending_comment) { create(:comment, article: article, user: user, status: 'pending') }
    let!(:rejected_comment) { create(:comment, article: article, user: user, status: 'rejected') }
    let!(:deleted_comment) { create(:comment, article: article, user: user, status: 'deleted') }

    describe '.visible' do
      it 'returns only approved comments' do
        expect(Comment.visible).to contain_exactly(approved_comment)
      end
    end

    describe '.awaiting_moderation' do
      it 'returns only pending comments' do
        expect(Comment.awaiting_moderation).to contain_exactly(pending_comment)
      end
    end

    describe '.not_deleted' do
      it 'returns comments that are not deleted' do
        expect(Comment.not_deleted).to contain_exactly(approved_comment, pending_comment, rejected_comment)
      end
    end
  end

  describe '#possible_status_events' do
    it 'returns available events for current state' do
      expect(comment.possible_status_events).to include('approve', 'reject', 'delete')
    end

    it 'returns different events after state change' do
      comment.approve!
      expect(comment.possible_status_events).to include('delete')
      expect(comment.possible_status_events).not_to include('approve', 'reject')
    end
  end

  describe 'HasStateTransitions concern' do
    it 'creates a state transition record after state change' do
      expect do
        comment.approve!
      end.to change(StateTransition, :count).by(1)

      transition = StateTransition.last
      expect(transition.transitionable).to eq(comment)
      expect(transition.from_state).to eq('pending')
      expect(transition.to_state).to eq('approved')
      expect(transition.event).to eq('approve!')
      expect(transition.user).to eq(user)
    end
  end
end
