require 'rails_helper'

RSpec.describe EventPolicy, type: :policy do
  subject { described_class }

  let(:admin) { create(:user, role: :admin) }
  let(:editor) { create(:user, role: :editor) }
  let(:viewer) { create(:user, role: :viewer) }
  let(:event) { Article2Created.new(data: { article2_id: SecureRandom.uuid }) }

  permissions :index? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, event)
    end

    it 'denies access to editor' do
      expect(subject).not_to permit(editor, event)
    end

    it 'denies access to viewer' do
      expect(subject).not_to permit(viewer, event)
    end

    it 'denies access when user is nil' do
      expect(subject).not_to permit(nil, event)
    end
  end
end

