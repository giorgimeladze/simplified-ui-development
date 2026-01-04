# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StateTransitionPolicy, type: :policy do
  subject { described_class }

  let(:admin) { create(:user, role: :admin) }
  let(:editor) { create(:user, role: :editor) }
  let(:viewer) { create(:user, role: :viewer) }
  let(:article) { create(:article, user: editor) }
  let(:state_transition) do
    article.submit!
    StateTransition.last
  end

  permissions :index? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, state_transition)
    end

    it 'denies access to editor' do
      expect(subject).not_to permit(editor, state_transition)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, state_transition)
    end

    it 'denies access when user is nil' do
      expect(subject).not_to permit(nil, state_transition)
    end
  end
end
