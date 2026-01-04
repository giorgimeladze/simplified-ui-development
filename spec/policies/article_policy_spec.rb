require 'rails_helper'

RSpec.describe ArticlePolicy, type: :policy do
  subject { described_class }

  let(:admin) { create(:user, role: :admin) }
  let(:editor) { create(:user, role: :editor) }
  let(:viewer) { create(:user, role: :viewer) }
  let(:article) { create(:article, user: editor) }

  permissions :articles_for_review? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, article)
    end

    it 'denies access to editor' do
      expect(subject).not_to permit(editor, article)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, article)
    end
  end

  permissions :deleted_articles? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, article)
    end

    it 'grants access to editor' do
      expect(subject).to permit(editor, article)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, article)
    end
  end

  permissions :show? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, article)
    end

    it 'grants access to editor' do
      expect(subject).to permit(editor, article)
    end

    it 'grants access to viewer' do
      expect(subject).to permit(viewer, article)
    end
  end

  permissions :new? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, article)
    end

    it 'grants access to editor' do
      expect(subject).to permit(editor, article)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, article)
    end
  end

  permissions :create? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, article)
    end

    it 'grants access to editor' do
      expect(subject).to permit(editor, article)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, article)
    end
  end

  permissions :submit? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, article)
    end

    it 'grants access to editor' do
      expect(subject).to permit(editor, article)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, article)
    end
  end

  permissions :approve_private? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, article)
    end

    it 'grants access to editor' do
      expect(subject).not_to permit(editor, article)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, article)
    end
  end

  permissions :reject? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, article)
    end

    it 'denies access to editor' do
      expect(subject).not_to permit(editor, article)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, article)
    end
  end

  permissions :resubmit? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, article)
    end

    it 'grants access to editor' do
      expect(subject).to permit(editor, article)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, article)
    end
  end

  permissions :archive? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, article)
    end

    it 'grants access to editor' do
      expect(subject).to permit(editor, article)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, article)
    end
  end

  permissions :publish? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, article)
    end

    it 'denies access to editor' do
      expect(subject).not_to permit(editor, article)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, article)
    end
  end

  permissions :make_visible? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, article)
    end

    it 'grants access to editor' do
      expect(subject).to permit(editor, article)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, article)
    end
  end

  permissions :make_invisible? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, article)
    end

    it 'grants access to editor' do
      expect(subject).to permit(editor, article)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, article)
    end
  end

  describe 'Scope' do
    let!(:admin_article) { create(:article, user: admin) }
    let!(:editor_article) { create(:article, user: editor) }
    let!(:viewer_article) { create(:article, user: viewer) }

    context 'when user is admin' do
      it 'returns all articles' do
        expect(ArticlePolicy::Scope.new(admin, Article).resolve).to contain_exactly(
          admin_article,
          editor_article,
          viewer_article
        )
      end
    end

    context 'when user is editor' do
      it 'returns only their own articles' do
        expect(ArticlePolicy::Scope.new(editor, Article).resolve).to contain_exactly(editor_article)
      end
    end

    context 'when user is viewer' do
      it 'returns only their own articles' do
        expect(ArticlePolicy::Scope.new(viewer, Article).resolve).to contain_exactly(viewer_article)
      end
    end
  end
end

