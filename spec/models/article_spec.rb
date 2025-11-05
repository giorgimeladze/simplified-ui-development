require 'rails_helper'

RSpec.describe Article, type: :model do
  let(:user) { create(:user, role: :editor) }
  let(:article) { create(:article, user: user) }

  describe 'associations' do
    it 'belongs to user' do
      expect(article).to respond_to(:user)
      expect(article.user).to eq(user)
    end

    it 'has many comments' do
      expect(article).to respond_to(:comments)
      comment = create(:comment, article: article, user: user)
      expect(article.comments).to include(comment)
    end

    it 'destroys comments when article is destroyed' do
      comment = create(:comment, article: article, user: user)
      article.destroy
      expect(Comment.exists?(comment.id)).to be false
    end

    it 'has many state transitions' do
      expect(article).to respond_to(:state_transitions)
    end
  end

  describe 'validations' do
    it 'requires user' do
      article = Article.new(title: 'Test', content: 'Content')
      expect(article).not_to be_valid
      expect(article.errors[:user]).to be_present
    end

    it 'requires title' do
      article = Article.new(user: user, content: 'Content')
      expect(article).not_to be_valid
      expect(article.errors[:title]).to be_present
    end

    it 'requires content' do
      article = Article.new(user: user, title: 'Title')
      expect(article).not_to be_valid
      expect(article.errors[:content]).to be_present
    end

    it 'validates rejection_feedback length' do
      article.rejection_feedback = 'a' * 1001
      expect(article).not_to be_valid
      expect(article.errors[:rejection_feedback]).to be_present
    end

    it 'allows blank rejection_feedback' do
      article.rejection_feedback = ''
      expect(article).to be_valid
    end
  end

  describe 'AASM state machine' do
    describe 'initial state' do
      it 'starts in draft state' do
        expect(article.status).to eq('draft')
      end
    end

    describe 'state transitions' do
      it 'transitions from draft to review on submit' do
        article.submit!
        expect(article.status).to eq('review')
      end

      it 'transitions from review to rejected on reject' do
        article.submit!
        article.reject!
        expect(article.status).to eq('rejected')
      end

      it 'transitions from review to privated on approve_private' do
        article.submit!
        article.approve_private!
        expect(article.status).to eq('privated')
      end

      it 'transitions from rejected to review on resubmit' do
        article.submit!
        article.reject!
        article.resubmit!
        expect(article.status).to eq('review')
      end

      it 'transitions from rejected to archived on archive' do
        article.submit!
        article.reject!
        article.archive!
        expect(article.status).to eq('archived')
      end

      it 'transitions from published to archived on archive' do
        article.submit!
        article.publish!
        article.archive!
        expect(article.status).to eq('archived')
      end

      it 'transitions from privated to archived on archive' do
        article.submit!
        article.approve_private!
        article.archive!
        expect(article.status).to eq('archived')
      end

      it 'transitions from review to published on publish' do
        article.submit!
        article.publish!
        expect(article.status).to eq('published')
      end

      it 'transitions from privated to published on make_visible' do
        article.submit!
        article.approve_private!
        article.make_visible!
        expect(article.status).to eq('published')
      end

      it 'transitions from published to privated on make_invisible' do
        article.submit!
        article.publish!
        article.make_invisible!
        expect(article.status).to eq('privated')
      end
    end

    describe 'invalid transitions' do
      it 'cannot transition from draft to rejected' do
        expect { article.reject! }.to raise_error(AASM::InvalidTransition)
      end

      it 'cannot transition from draft to published' do
        expect { article.publish! }.to raise_error(AASM::InvalidTransition)
      end
    end
  end

  describe 'scopes' do
    let!(:published_article) { create(:article, user: user, status: 'published') }
    let!(:draft_article) { create(:article, user: user, status: 'draft') }
    let!(:review_article) { create(:article, user: user, status: 'review') }
    let!(:privated_article) { create(:article, user: user, status: 'privated') }

    describe '.visible' do
      it 'returns only published articles' do
        expect(Article.visible).to contain_exactly(published_article)
      end
    end

    describe '.admin_visible' do
      it 'returns published, privated, and review articles' do
        expect(Article.admin_visible).to contain_exactly(published_article, privated_article, review_article)
      end
    end
  end

  describe '#visible_comments' do
    let(:article) { create(:article, user: user) }
    let(:author) { create(:user, role: :viewer) }
    let!(:approved_comment) { create(:comment, article: article, status: 'approved', user: author) }
    let!(:rejected_comment) { create(:comment, article: article, status: 'rejected', user: author) }
    let!(:pending_comment) { create(:comment, article: article, status: 'pending', user: author) }

    context 'when user is nil' do
      it 'returns only approved comments' do
        expect(article.visible_comments(nil)).to contain_exactly(approved_comment)
      end
    end

    context 'when user is admin' do
      let(:admin) { create(:user, role: :admin) }

      it 'returns approved and rejected comments' do
        expect(article.visible_comments(admin)).to contain_exactly(approved_comment, rejected_comment)
      end
    end

    context 'when user is regular user' do
      it 'returns approved comments and their own rejected comments' do
        other_user = create(:user, role: :viewer)
        own_rejected = create(:comment, article: article, status: 'rejected', user: other_user)
        
        expect(article.visible_comments(other_user)).to contain_exactly(approved_comment, own_rejected)
      end
    end
  end

  describe '#possible_status_events' do
    it 'returns available events for current state' do
      expect(article.possible_status_events).to include('submit')
    end

    it 'returns different events after state change' do
      article.submit!
      expect(article.possible_status_events).to include('reject', 'approve_private', 'publish')
    end
  end

  describe 'HasStateTransitions concern' do
    it 'creates a state transition record after state change' do
      expect {
        article.submit!
      }.to change(StateTransition, :count).by(1)
      
      transition = StateTransition.last
      expect(transition.transitionable).to eq(article)
      expect(transition.from_state).to eq('draft')
      expect(transition.to_state).to eq('review')
      expect(transition.event).to eq('submit!')
      expect(transition.user).to eq(user)
    end
  end
end
