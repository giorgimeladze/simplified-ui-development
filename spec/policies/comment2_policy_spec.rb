# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Comment2Policy, type: :policy do
  subject { described_class }

  let(:admin) { create(:user, role: :admin) }
  let(:editor) { create(:user, role: :editor) }
  let(:viewer) { create(:user, role: :viewer) }
  let(:article2) do
    Article2ReadModel.create!(
      id: SecureRandom.uuid,
      title: 'Test Article',
      content: 'Test content',
      author_id: editor.id,
      state: 'draft'
    )
  end
  let(:comment2) do
    Comment2ReadModel.create!(
      id: SecureRandom.uuid,
      text: 'Test comment',
      article2_id: article2.id,
      author_id: viewer.id,
      state: 'pending'
    )
  end

  permissions :index? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, comment2)
    end

    it 'grants access to editor' do
      expect(subject).to permit(editor, comment2)
    end

    it 'grants access to viewer' do
      expect(subject).to permit(viewer, comment2)
    end
  end

  permissions :show? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, comment2)
    end

    it 'grants access to editor' do
      expect(subject).to permit(editor, comment2)
    end

    it 'grants access to viewer' do
      expect(subject).to permit(viewer, comment2)
    end
  end

  permissions :pending_comment2s? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, comment2)
    end

    it 'denies access to editor' do
      expect(subject).not_to permit(editor, comment2)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, comment2)
    end
  end

  permissions :create? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, comment2)
    end

    it 'grants access to editor' do
      expect(subject).to permit(editor, comment2)
    end

    it 'grants access to viewer' do
      expect(subject).to permit(viewer, comment2)
    end

    it 'denies access when user is nil' do
      expect(subject).not_to permit(nil, comment2)
    end
  end

  permissions :update? do
    context 'when comment2 is pending' do
      let(:comment2) do
        Comment2ReadModel.create!(
          id: SecureRandom.uuid,
          text: 'Test comment',
          article2_id: article2.id,
          author_id: viewer.id,
          state: 'pending'
        )
      end

      it 'grants access to comment owner' do
        expect(subject).to permit(viewer, comment2)
      end

      it 'denies access to other users' do
        other_user = create(:user, role: :viewer)
        expect(subject).not_to permit(other_user, comment2)
      end
    end

    context 'when comment2 is rejected' do
      let(:comment2) do
        Comment2ReadModel.create!(
          id: SecureRandom.uuid,
          text: 'Test comment',
          article2_id: article2.id,
          author_id: viewer.id,
          state: 'rejected'
        )
      end

      it 'grants access to comment owner' do
        expect(subject).to permit(viewer, comment2)
      end

      it 'denies access to other users' do
        other_user = create(:user, role: :viewer)
        expect(subject).not_to permit(other_user, comment2)
      end
    end

    context 'when comment2 is approved' do
      let(:comment2) do
        Comment2ReadModel.create!(
          id: SecureRandom.uuid,
          text: 'Test comment',
          article2_id: article2.id,
          author_id: viewer.id,
          state: 'approved'
        )
      end

      it 'denies access to comment owner' do
        expect(subject).not_to permit(viewer, comment2)
      end
    end

    it 'denies access when user is nil' do
      expect(subject).not_to permit(nil, comment2)
    end
  end

  permissions :approve? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, comment2)
    end

    it 'denies access to editor' do
      expect(subject).not_to permit(editor, comment2)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, comment2)
    end

    it 'denies access when user is nil' do
      expect(subject).not_to permit(nil, comment2)
    end
  end

  permissions :reject? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, comment2)
    end

    it 'denies access to editor' do
      expect(subject).not_to permit(editor, comment2)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, comment2)
    end

    it 'denies access when user is nil' do
      expect(subject).not_to permit(nil, comment2)
    end
  end

  permissions :delete? do
    let(:comment2) do
      Comment2ReadModel.create!(
        id: SecureRandom.uuid,
        text: 'Test comment',
        article2_id: article2.id,
        author_id: editor.id,
        state: 'approved'
      )
    end

    it 'grants access to comment owner' do
      expect(subject).to permit(editor, comment2)
    end

    it 'grants access to admin' do
      expect(subject).to permit(admin, comment2)
    end

    it 'denies access to other users' do
      other_user = create(:user, role: :viewer)
      expect(subject).not_to permit(other_user, comment2)
    end

    it 'denies access when user is nil' do
      expect(subject).not_to permit(nil, comment2)
    end
  end

  permissions :restore? do
    let(:comment2) do
      Comment2ReadModel.create!(
        id: SecureRandom.uuid,
        text: 'Test comment',
        article2_id: article2.id,
        author_id: editor.id,
        state: 'deleted'
      )
    end
    it 'grants access to admin' do
      expect(subject).to permit(admin, comment2)
    end

    it 'grants access to editor' do
      expect(subject).to permit(editor, comment2)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, comment2)
    end

    it 'denies access when user is nil' do
      expect(subject).not_to permit(nil, comment2)
    end
  end
end
