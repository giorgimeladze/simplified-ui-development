# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Comment2Commands do
  let(:user) { create(:user, role: :viewer) }
  let(:event_store) { Rails.application.config.x.event_store }
  let(:repository) { EventRepository.new(client: event_store) }
  let(:article2_id) { SecureRandom.uuid }

  before do
    allow(EventRepository).to receive(:new).and_return(repository)
  end

  describe '.create_comment' do
    let(:text) { 'Test comment' }

    it 'creates a new comment aggregate' do
      result = Comment2Commands.create_comment(text, article2_id, user)

      expect(result[:success]).to be true
      expect(result[:comment2_id]).to be_present
    end

    it 'stores Comment2Created event' do
      expect_any_instance_of(EventRepository).to receive(:store).with(
        an_instance_of(Comment2Aggregate),
        Comment2Created,
        expected_version: :none
      )

      Comment2Commands.create_comment(text, article2_id, user)
    end

    it 'generates a unique aggregate id' do
      result1 = Comment2Commands.create_comment(text, article2_id, user)
      result2 = Comment2Commands.create_comment(text, article2_id, user)

      expect(result1[:comment2_id]).not_to eq(result2[:comment2_id])
    end
  end

  describe '.approve_comment' do
    let(:comment2_id) { SecureRandom.uuid }

    before do
      aggregate = Comment2Aggregate.new(comment2_id)
      aggregate.create(text: 'Test comment', article2_id: article2_id, author_id: user.id)
      repository.store(aggregate, Comment2Created, expected_version: :none)
    end

    it 'approves the comment' do
      result = Comment2Commands.approve_comment(comment2_id, user)

      expect(result[:success]).to be true
      expect(result[:comment2_id]).to eq(comment2_id)
    end

    it 'stores Comment2Approved event' do
      expect_any_instance_of(EventRepository).to receive(:store).with(
        an_instance_of(Comment2Aggregate),
        Comment2Approved
      )

      Comment2Commands.approve_comment(comment2_id, user)
    end
  end

  describe '.reject_comment' do
    let(:comment2_id) { SecureRandom.uuid }
    let(:rejection_feedback) { 'Inappropriate content' }

    before do
      aggregate = Comment2Aggregate.new(comment2_id)
      aggregate.create(text: 'Test comment', article2_id: article2_id, author_id: user.id)
      repository.store(aggregate, Comment2Created, expected_version: :none)
    end

    it 'rejects the comment' do
      result = Comment2Commands.reject_comment(comment2_id, rejection_feedback, user)

      expect(result[:success]).to be true
      expect(result[:comment2_id]).to eq(comment2_id)
    end

    it 'returns error if rejection_feedback is blank' do
      result = Comment2Commands.reject_comment(comment2_id, '', user)

      expect(result[:success]).to be false
      expect(result[:errors]).to eq('Rejection feedback is required')
    end

    it 'returns error if rejection_feedback is nil' do
      result = Comment2Commands.reject_comment(comment2_id, nil, user)

      expect(result[:success]).to be false
      expect(result[:errors]).to eq('Rejection feedback is required')
    end

    it 'stores Comment2Rejected event when feedback is provided' do
      expect_any_instance_of(EventRepository).to receive(:store).with(
        an_instance_of(Comment2Aggregate),
        Comment2Rejected
      )

      Comment2Commands.reject_comment(comment2_id, rejection_feedback, user)
    end

    it 'does not store event when feedback is blank' do
      expect_any_instance_of(EventRepository).not_to receive(:store)

      Comment2Commands.reject_comment(comment2_id, '', user)
    end
  end

  describe '.delete_comment' do
    let(:comment2_id) { SecureRandom.uuid }

    before do
      aggregate = Comment2Aggregate.new(comment2_id)
      aggregate.create(text: 'Test comment', article2_id: article2_id, author_id: user.id)
      repository.store(aggregate, Comment2Created, expected_version: :none)
    end

    it 'deletes the comment' do
      result = Comment2Commands.delete_comment(comment2_id, user)

      expect(result[:success]).to be true
      expect(result[:comment2_id]).to eq(comment2_id)
    end

    it 'stores Comment2Deleted event' do
      expect_any_instance_of(EventRepository).to receive(:store).with(
        an_instance_of(Comment2Aggregate),
        Comment2Deleted
      )

      Comment2Commands.delete_comment(comment2_id, user)
    end
  end

  describe '.restore_comment' do
    let(:comment2_id) { SecureRandom.uuid }

    before do
      aggregate = Comment2Aggregate.new(comment2_id)
      aggregate.create(text: 'Test comment', article2_id: article2_id, author_id: user.id)
      repository.store(aggregate, Comment2Created, expected_version: :none)
      aggregate = repository.load(Comment2Aggregate, comment2_id)
      aggregate.delete(actor_id: user.id)
      repository.store(aggregate, Comment2Deleted)
    end

    it 'restores the comment' do
      result = Comment2Commands.restore_comment(comment2_id, user)

      expect(result[:success]).to be true
      expect(result[:comment2_id]).to eq(comment2_id)
    end

    it 'stores Comment2Restored event' do
      expect_any_instance_of(EventRepository).to receive(:store).with(
        an_instance_of(Comment2Aggregate),
        Comment2Restored
      )

      Comment2Commands.restore_comment(comment2_id, user)
    end
  end

  describe '.update_comment' do
    let(:comment2_id) { SecureRandom.uuid }
    let(:new_text) { 'Updated comment text' }

    before do
      aggregate = Comment2Aggregate.new(comment2_id)
      aggregate.create(text: 'Original comment', article2_id: article2_id, author_id: user.id)
      repository.store(aggregate, Comment2Created, expected_version: :none)
      aggregate = repository.load(Comment2Aggregate, comment2_id)
      aggregate.reject(rejection_feedback: 'Feedback', actor_id: user.id)
      repository.store(aggregate, Comment2Rejected)
    end

    it 'updates the comment' do
      result = Comment2Commands.update_comment(comment2_id, new_text, user)

      expect(result[:success]).to be true
      expect(result[:comment2_id]).to eq(comment2_id)
    end

    it 'stores Comment2Updated event' do
      expect_any_instance_of(EventRepository).to receive(:store).with(
        an_instance_of(Comment2Aggregate),
        Comment2Updated
      )

      Comment2Commands.update_comment(comment2_id, new_text, user)
    end
  end
end
