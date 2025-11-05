require 'rails_helper'

RSpec.describe Comment2ReadModel, type: :model do
  let(:user) { create(:user, role: :viewer) }
  let(:article2) do
    Article2ReadModel.create!(
      id: SecureRandom.uuid,
      title: 'Test Article',
      content: 'Test content',
      author_id: user.id,
      state: 'draft'
    )
  end
  let(:comment2) do
    Comment2ReadModel.create!(
      id: SecureRandom.uuid,
      text: 'Test comment',
      article2_id: article2.id,
      author_id: user.id,
      state: 'pending'
    )
  end

  describe 'table configuration' do
    it 'uses comment2_read_models table' do
      expect(Comment2ReadModel.table_name).to eq('comment2_read_models')
    end

    it 'uses id as primary key' do
      expect(Comment2ReadModel.primary_key).to eq('id')
    end
  end

  describe 'scopes' do
    let!(:comment1) do
      Comment2ReadModel.create!(
        id: SecureRandom.uuid,
        text: 'Comment 1',
        article2_id: article2.id,
        author_id: user.id,
        state: 'pending'
      )
    end
    let(:other_article) do
      Article2ReadModel.create!(
        id: SecureRandom.uuid,
        title: 'Other Article',
        content: 'Other content',
        author_id: user.id,
        state: 'draft'
      )
    end
    let!(:comment2_other) do
      Comment2ReadModel.create!(
        id: SecureRandom.uuid,
        text: 'Comment 2',
        article2_id: other_article.id,
        author_id: user.id,
        state: 'pending'
      )
    end

    describe '.for_article' do
      it 'returns comments for specific article' do
        expect(Comment2ReadModel.for_article(article2.id)).to contain_exactly(comment1)
      end
    end
  end

  describe '#hypermedia_model_name' do
    it 'returns Comment2' do
      expect(comment2.hypermedia_model_name).to eq('Comment2')
    end
  end

  describe '#possible_status_events' do
    context 'when state is pending' do
      it 'returns approve, reject, delete' do
        comment2.update!(state: 'pending')
        expect(comment2.possible_status_events).to eq(%w[approve reject delete])
      end
    end

    context 'when state is approved' do
      it 'returns delete' do
        comment2.update!(state: 'approved')
        expect(comment2.possible_status_events).to eq(%w[delete])
      end
    end

    context 'when state is rejected' do
      it 'returns resubmit, delete' do
        comment2.update!(state: 'rejected')
        expect(comment2.possible_status_events).to eq(%w[resubmit delete])
      end
    end

    context 'when state is deleted' do
      it 'returns restore' do
        comment2.update!(state: 'deleted')
        expect(comment2.possible_status_events).to eq(%w[restore])
      end
    end

    context 'when state is unknown' do
      it 'returns empty array' do
        comment2.update!(state: 'unknown')
        expect(comment2.possible_status_events).to eq([])
      end
    end
  end

  describe '#policy' do
    it 'returns Comment2Policy instance' do
      policy = comment2.policy(user)
      expect(policy).to be_a(Comment2Policy)
      expect(policy.record).to eq(comment2)
      expect(policy.user).to eq(user)
    end
  end

  describe 'HasHypermediaLinks concern' do
    it 'includes HasHypermediaLinks' do
      expect(Comment2ReadModel.included_modules).to include(HasHypermediaLinks)
    end

    it 'responds to hypermedia_new_links' do
      expect(comment2).to respond_to(:hypermedia_new_links)
    end

    it 'responds to hypermedia_edit_links' do
      expect(comment2).to respond_to(:hypermedia_edit_links)
    end
  end
end

