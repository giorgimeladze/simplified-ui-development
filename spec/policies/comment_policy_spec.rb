require 'rails_helper'

RSpec.describe CommentPolicy, type: :policy do
  subject { described_class }

  let(:admin) { create(:user, role: :admin) }
  let(:editor) { create(:user, role: :editor) }
  let(:viewer) { create(:user, role: :viewer) }
  let(:article) { create(:article, user: editor) }
  let(:comment) { create(:comment, article: article, user: viewer) }

  permissions :index? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, comment)
    end

    it 'grants access to editor' do
      expect(subject).to permit(editor, comment)
    end

    it 'grants access to viewer' do
      expect(subject).to permit(viewer, comment)
    end
  end

  permissions :show? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, comment)
    end

    it 'grants access to editor' do
      expect(subject).to permit(editor, comment)
    end

    it 'grants access to viewer' do
      expect(subject).to permit(viewer, comment)
    end
  end

  permissions :create? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, comment)
    end

    it 'grants access to editor' do
      expect(subject).to permit(editor, comment)
    end

    it 'grants access to viewer' do
      expect(subject).to permit(viewer, comment)
    end

    it 'denies access when user is nil' do
      expect(subject).not_to permit(nil, comment)
    end
  end

  permissions :update? do
    context 'when comment is pending' do
      let(:comment) { create(:comment, article: article, user: viewer, status: 'pending') }

      it 'grants access to comment owner' do
        expect(subject).to permit(viewer, comment)
      end

      it 'denies access to other users' do
        other_user = create(:user, role: :viewer)
        expect(subject).not_to permit(other_user, comment)
      end

      it 'denies access to admin' do
        expect(subject).not_to permit(admin, comment)
      end
    end

    context 'when comment is rejected' do
      let(:comment) { create(:comment, article: article, user: viewer, status: 'rejected') }

      it 'grants access to comment owner' do
        expect(subject).to permit(viewer, comment)
      end

      it 'denies access to other users' do
        other_user = create(:user, role: :viewer)
        expect(subject).not_to permit(other_user, comment)
      end
    end

    context 'when comment is approved' do
      let(:comment) { create(:comment, article: article, user: viewer, status: 'approved') }

      it 'denies access to comment owner' do
        expect(subject).not_to permit(viewer, comment)
      end
    end

    it 'denies access when user is nil' do
      expect(subject).not_to permit(nil, comment)
    end
  end

  permissions :approve? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, comment)
    end

    it 'denies access to editor' do
      expect(subject).not_to permit(editor, comment)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, comment)
    end

    it 'denies access when user is nil' do
      expect(subject).not_to permit(nil, comment)
    end
  end

  permissions :reject? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, comment)
    end

    it 'denies access to editor' do
      expect(subject).not_to permit(editor, comment)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, comment)
    end

    it 'denies access when user is nil' do
      expect(subject).not_to permit(nil, comment)
    end
  end

  permissions :delete? do
    it 'grants access to comment owner' do
      expect(subject).to permit(viewer, comment)
    end

    it 'grants access to admin' do
      expect(subject).to permit(admin, comment)
    end

    it 'grants access to editor' do
      expect(subject).to permit(editor, comment)
    end

    it 'denies access to other users' do
      other_user = create(:user, role: :viewer)
      expect(subject).not_to permit(other_user, comment)
    end

    it 'denies access when user is nil' do
      expect(subject).not_to permit(nil, comment)
    end
  end

  permissions :restore? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, comment)
    end

    it 'grants access to editor' do
      expect(subject).to permit(editor, comment)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, comment)
    end

    it 'denies access when user is nil' do
      expect(subject).not_to permit(nil, comment)
    end
  end
end

