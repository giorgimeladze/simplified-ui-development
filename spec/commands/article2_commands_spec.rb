# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Article2Commands do
  let(:user) { create(:user, role: :editor) }
  let(:event_store) { Rails.application.config.x.event_store }
  let(:repository) { EventRepository.new(client: event_store) }

  before do
    allow(EventRepository).to receive(:new).and_return(repository)
  end

  describe '.create_article' do
    let(:title) { 'Test Article' }
    let(:content) { 'Test content' }

    it 'creates a new article aggregate' do
      result = Article2Commands.create_article(title, content, user)

      expect(result[:success]).to be true
      expect(result[:article2_id]).to be_present
    end

    it 'stores Article2Created event' do
      expect_any_instance_of(EventRepository).to receive(:store).with(
        an_instance_of(Article2Aggregate),
        Article2Created,
        hash_including(expected_version: :none)
      )

      Article2Commands.create_article(title, content, user)
    end

    it 'generates a unique aggregate id' do
      result1 = Article2Commands.create_article(title, content, user)
      result2 = Article2Commands.create_article(title, content, user)

      expect(result1[:article2_id]).not_to eq(result2[:article2_id])
    end
  end

  describe '.submit_article' do
    let(:article2_id) { SecureRandom.uuid }

    before do
      aggregate = Article2Aggregate.new(article2_id)
      aggregate.create(title: 'Test', content: 'Content', author_id: user.id)
      repository.store(aggregate, Article2Created, expected_version: :none)
    end

    it 'submits the article' do
      result = Article2Commands.submit_article(article2_id, user)

      expect(result[:success]).to be true
      expect(result[:article2_id]).to eq(article2_id)
    end

    it 'stores Article2Submitted event' do
      expect_any_instance_of(EventRepository).to receive(:store).with(
        an_instance_of(Article2Aggregate),
        Article2Submitted
      )

      Article2Commands.submit_article(article2_id, user)
    end
  end

  describe '.reject_article' do
    let(:article2_id) { SecureRandom.uuid }
    let(:rejection_feedback) { 'Needs improvement' }

    before do
      aggregate = Article2Aggregate.new(article2_id)
      aggregate.create(title: 'Test', content: 'Content', author_id: user.id)
      repository.store(aggregate, Article2Created, expected_version: :none)
      aggregate = repository.load(Article2Aggregate, article2_id)
      aggregate.submit(actor_id: user.id)
      repository.store(aggregate, Article2Submitted)
    end

    it 'rejects the article' do
      result = Article2Commands.reject_article(article2_id, rejection_feedback, user)

      expect(result[:success]).to be true
      expect(result[:article2_id]).to eq(article2_id)
    end

    it 'stores Article2Rejected event' do
      expect_any_instance_of(EventRepository).to receive(:store).with(
        an_instance_of(Article2Aggregate),
        Article2Rejected
      )

      Article2Commands.reject_article(article2_id, rejection_feedback, user)
    end
  end

  describe '.approve_private_article' do
    let(:article2_id) { SecureRandom.uuid }

    before do
      aggregate = Article2Aggregate.new(article2_id)
      aggregate.create(title: 'Test', content: 'Content', author_id: user.id)
      repository.store(aggregate, Article2Created, expected_version: :none)
      aggregate = repository.load(Article2Aggregate, article2_id)
      aggregate.submit(actor_id: user.id)
      repository.store(aggregate, Article2Submitted)
    end

    it 'approves the article privately' do
      result = Article2Commands.approve_private_article(article2_id, user)

      expect(result[:success]).to be true
      expect(result[:article2_id]).to eq(article2_id)
    end

    it 'stores Article2ApprovedPrivate event' do
      expect_any_instance_of(EventRepository).to receive(:store).with(
        an_instance_of(Article2Aggregate),
        Article2ApprovedPrivate
      )

      Article2Commands.approve_private_article(article2_id, user)
    end
  end

  describe '.publish_article' do
    let(:article2_id) { SecureRandom.uuid }

    before do
      aggregate = Article2Aggregate.new(article2_id)
      aggregate.create(title: 'Test', content: 'Content', author_id: user.id)
      repository.store(aggregate, Article2Created, expected_version: :none)
      aggregate = repository.load(Article2Aggregate, article2_id)
      aggregate.submit(actor_id: user.id)
      repository.store(aggregate, Article2Submitted)
    end

    it 'publishes the article' do
      result = Article2Commands.publish_article(article2_id, user)

      expect(result[:success]).to be true
      expect(result[:article2_id]).to eq(article2_id)
    end

    it 'stores Article2Published event' do
      expect_any_instance_of(EventRepository).to receive(:store).with(
        an_instance_of(Article2Aggregate),
        Article2Published
      )

      Article2Commands.publish_article(article2_id, user)
    end
  end

  describe '.archive_article' do
    let(:article2_id) { SecureRandom.uuid }

    before do
      aggregate = Article2Aggregate.new(article2_id)
      aggregate.create(title: 'Test', content: 'Content', author_id: user.id)
      repository.store(aggregate, Article2Created, expected_version: :none)
      aggregate = repository.load(Article2Aggregate, article2_id)
      aggregate.submit(actor_id: user.id)
      repository.store(aggregate, Article2Submitted)
      aggregate = repository.load(Article2Aggregate, article2_id)
      aggregate.publish(actor_id: user.id)
      repository.store(aggregate, Article2Published)
    end

    it 'archives the article' do
      result = Article2Commands.archive_article(article2_id, user)

      expect(result[:success]).to be true
      expect(result[:article2_id]).to eq(article2_id)
    end

    it 'stores Article2Archived event' do
      expect_any_instance_of(EventRepository).to receive(:store).with(
        an_instance_of(Article2Aggregate),
        Article2Archived
      )

      Article2Commands.archive_article(article2_id, user)
    end
  end

  describe '.update_article' do
    let(:article2_id) { SecureRandom.uuid }
    let(:new_title) { 'Updated Title' }
    let(:new_content) { 'Updated content' }

    before do
      aggregate = Article2Aggregate.new(article2_id)
      aggregate.create(title: 'Original', content: 'Original content', author_id: user.id)
      repository.store(aggregate, Article2Created, expected_version: :none)
    end

    it 'updates the article' do
      result = Article2Commands.update_article(article2_id, new_title, new_content, user)

      expect(result[:success]).to be true
      expect(result[:article2_id]).to eq(article2_id)
    end

    it 'stores Article2Updated event' do
      expect_any_instance_of(EventRepository).to receive(:store).with(
        an_instance_of(Article2Aggregate),
        Article2Updated
      )

      Article2Commands.update_article(article2_id, new_title, new_content, user)
    end
  end

  describe '.resubmit_article' do
    let(:article2_id) { SecureRandom.uuid }

    before do
      aggregate = Article2Aggregate.new(article2_id)
      aggregate.create(title: 'Test', content: 'Content', author_id: user.id)
      repository.store(aggregate, Article2Created, expected_version: :none)
      aggregate = repository.load(Article2Aggregate, article2_id)
      aggregate.submit(actor_id: user.id)
      repository.store(aggregate, Article2Submitted)
      aggregate = repository.load(Article2Aggregate, article2_id)
      aggregate.reject(rejection_feedback: 'Feedback', actor_id: user.id)
      repository.store(aggregate, Article2Rejected)
    end

    it 'resubmits the article' do
      result = Article2Commands.resubmit_article(article2_id, user)

      expect(result[:success]).to be true
      expect(result[:article2_id]).to eq(article2_id)
    end

    it 'stores Article2Submitted event' do
      expect_any_instance_of(EventRepository).to receive(:store).with(
        an_instance_of(Article2Aggregate),
        Article2Submitted
      )

      Article2Commands.resubmit_article(article2_id, user)
    end
  end

  describe '.make_visible_article' do
    let(:article2_id) { SecureRandom.uuid }

    before do
      aggregate = Article2Aggregate.new(article2_id)
      aggregate.create(title: 'Test', content: 'Content', author_id: user.id)
      repository.store(aggregate, Article2Created, expected_version: :none)
      aggregate = repository.load(Article2Aggregate, article2_id)
      aggregate.submit(actor_id: user.id)
      repository.store(aggregate, Article2Submitted)
      aggregate = repository.load(Article2Aggregate, article2_id)
      aggregate.approve_private(actor_id: user.id)
      repository.store(aggregate, Article2ApprovedPrivate)
    end

    it 'makes the article visible' do
      result = Article2Commands.make_visible_article(article2_id, user)

      expect(result[:success]).to be true
      expect(result[:article2_id]).to eq(article2_id)
    end

    it 'stores Article2Published event' do
      expect_any_instance_of(EventRepository).to receive(:store).with(
        an_instance_of(Article2Aggregate),
        Article2Published
      )

      Article2Commands.make_visible_article(article2_id, user)
    end
  end

  describe '.make_invisible_article' do
    let(:article2_id) { SecureRandom.uuid }

    before do
      aggregate = Article2Aggregate.new(article2_id)
      aggregate.create(title: 'Test', content: 'Content', author_id: user.id)
      repository.store(aggregate, Article2Created, expected_version: :none)
      aggregate = repository.load(Article2Aggregate, article2_id)
      aggregate.submit(actor_id: user.id)
      repository.store(aggregate, Article2Submitted)
      aggregate = repository.load(Article2Aggregate, article2_id)
      aggregate.publish(actor_id: user.id)
      repository.store(aggregate, Article2Published)
    end

    it 'makes the article invisible' do
      result = Article2Commands.make_invisible_article(article2_id, user)

      expect(result[:success]).to be true
      expect(result[:article2_id]).to eq(article2_id)
    end

    it 'stores Article2ApprovedPrivate event' do
      expect_any_instance_of(EventRepository).to receive(:store).with(
        an_instance_of(Article2Aggregate),
        Article2ApprovedPrivate
      )

      Article2Commands.make_invisible_article(article2_id, user)
    end
  end
end
