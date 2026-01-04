# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Article2ReadModel, type: :model do
  let(:user) { create(:user, role: :editor) }
  let(:article2) do
    Article2ReadModel.create!(
      id: SecureRandom.uuid,
      title: 'Test Article',
      content: 'Test content',
      author_id: user.id,
      state: 'draft'
    )
  end

  describe 'table configuration' do
    it 'uses article2_read_models table' do
      expect(Article2ReadModel.table_name).to eq('article2_read_models')
    end

    it 'uses id as primary key' do
      expect(Article2ReadModel.primary_key).to eq('id')
    end

    it 'has correct model name for URL generation' do
      expect(Article2ReadModel.model_name.name).to eq('Article2')
    end
  end

  describe 'scopes' do
    let!(:article1) do
      Article2ReadModel.create!(
        id: SecureRandom.uuid,
        title: 'Article 1',
        content: 'Content 1',
        author_id: user.id,
        state: 'draft'
      )
    end
    let!(:article2_other) do
      Article2ReadModel.create!(
        id: SecureRandom.uuid,
        title: 'Article 2',
        content: 'Content 2',
        author_id: create(:user).id,
        state: 'draft'
      )
    end

    describe '.by_author' do
      it 'returns articles by specific author' do
        expect(Article2ReadModel.by_author(user.id)).to contain_exactly(article1)
      end
    end
  end

  describe '#hypermedia_model_name' do
    it 'returns Article2' do
      expect(article2.hypermedia_model_name).to eq('Article2')
    end
  end

  describe '#possible_status_events' do
    context 'when state is draft' do
      it 'returns submit' do
        article2.update!(state: 'draft')
        expect(article2.possible_status_events).to eq(%w[submit])
      end
    end

    context 'when state is review' do
      it 'returns reject, approve_private, publish' do
        article2.update!(state: 'review')
        expect(article2.possible_status_events).to eq(%w[reject approve_private publish])
      end
    end

    context 'when state is rejected' do
      it 'returns resubmit, archive' do
        article2.update!(state: 'rejected')
        expect(article2.possible_status_events).to eq(%w[resubmit archive])
      end
    end

    context 'when state is privated' do
      it 'returns make_visible, archive' do
        article2.update!(state: 'privated')
        expect(article2.possible_status_events).to eq(%w[make_visible archive])
      end
    end

    context 'when state is published' do
      it 'returns make_invisible, archive' do
        article2.update!(state: 'published')
        expect(article2.possible_status_events).to eq(%w[make_invisible archive])
      end
    end

    context 'when state is unknown' do
      it 'returns empty array' do
        article2.update!(state: 'unknown')
        expect(article2.possible_status_events).to eq([])
      end
    end
  end

  describe '#policy' do
    it 'returns Article2Policy instance' do
      policy = article2.policy(user)
      expect(policy).to be_a(Article2Policy)
      expect(policy.record).to eq(article2)
      expect(policy.user).to eq(user)
    end
  end

  describe '#comments' do
    let(:comment2) do
      Comment2ReadModel.create!(
        id: SecureRandom.uuid,
        text: 'Test comment',
        article2_id: article2.id,
        author_id: user.id,
        state: 'pending'
      )
    end

    it 'returns associated comments' do
      comment2 # Create the comment
      expect(article2.comments).to include(comment2)
    end
  end

  describe 'HasHypermediaLinks concern' do
    it 'includes HasHypermediaLinks' do
      expect(Article2ReadModel.included_modules).to include(HasHypermediaLinks)
    end

    it 'responds to hypermedia_new_links' do
      expect(article2).to respond_to(:hypermedia_new_links)
    end

    it 'responds to hypermedia_edit_links' do
      expect(article2).to respond_to(:hypermedia_edit_links)
    end
  end
end
