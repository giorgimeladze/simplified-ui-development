# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventRepository do
  let(:event_store) { Rails.application.config.x.event_store }
  let(:repository) { EventRepository.new(client: event_store) }
  let(:aggregate_id) { SecureRandom.uuid }

  describe '#initialize' do
    it 'initializes with default event store client' do
      repo = EventRepository.new
      expect(repo.instance_variable_get(:@client)).to eq(event_store)
    end

    it 'initializes with custom client' do
      custom_client = double('EventStoreClient')
      repo = EventRepository.new(client: custom_client)
      expect(repo.instance_variable_get(:@client)).to eq(custom_client)
    end
  end

  describe '#load' do
    let(:aggregate_class) { Article2Aggregate }

    context 'when stream has no events' do
      it 'returns a new aggregate with unknown status' do
        aggregate = repository.load(aggregate_class, aggregate_id)

        expect(aggregate).to be_a(aggregate_class)
        expect(aggregate.id).to eq(aggregate_id)
        expect(aggregate.status).to eq('unknown')
      end
    end

    context 'when stream has events' do
      before do
        aggregate = aggregate_class.new(aggregate_id)
        aggregate.create(title: 'Test', content: 'Content', author_id: create(:user).id)
        repository.store(aggregate, Article2Created, expected_version: :none)
      end

      it 'loads aggregate and applies all events' do
        loaded_aggregate = repository.load(aggregate_class, aggregate_id)

        expect(loaded_aggregate).to be_a(aggregate_class)
        expect(loaded_aggregate.id).to eq(aggregate_id)
        expect(loaded_aggregate.status).to eq('draft')
        expect(loaded_aggregate.title).to eq('Test')
        expect(loaded_aggregate.content).to eq('Content')
      end
    end

    context 'with multiple events' do
      before do
        aggregate = aggregate_class.new(aggregate_id)
        aggregate.create(title: 'Test', content: 'Content', author_id: create(:user).id)
        repository.store(aggregate, Article2Created, expected_version: :none)
        aggregate = repository.load(aggregate_class, aggregate_id)
        aggregate.submit(actor_id: create(:user).id)
        repository.store(aggregate, Article2Submitted)
      end

      it 'applies all events in order' do
        loaded_aggregate = repository.load(aggregate_class, aggregate_id)

        expect(loaded_aggregate.status).to eq('review')
        expect(loaded_aggregate.title).to eq('Test')
      end
    end
  end

  describe '#store' do
    let(:aggregate) { Article2Aggregate.new(aggregate_id) }
    let(:user) { create(:user) }

    before do
      aggregate.create(title: 'Test', content: 'Content', author_id: user.id)
    end

    it 'publishes the event to the event store' do
      expect(event_store).to receive(:publish).with(
        an_instance_of(Article2Created),
        stream_name: "Article2$#{aggregate_id}",
        expected_version: :none
      )

      repository.store(aggregate, Article2Created, expected_version: :none)
    end

    it 'clears unpublished events after publishing' do
      expect(aggregate.unpublished_events.count).to be > 0
      repository.store(aggregate, Article2Created, expected_version: :none)
      expect(aggregate.unpublished_events.count).to eq(0)
    end

    it 'only publishes events of the specified class' do
      aggregate.submit(actor_id: user.id)
      # Now aggregate has both Article2Created and Article2Submitted
      # But we're only storing Article2Created
      repository.store(aggregate, Article2Created, expected_version: :none)

      # The Article2Submitted should still be in unpublished_events
      # But the store method only publishes the last event if it matches the class
      expect(aggregate.unpublished_events.count).to eq(2)
    end

    context 'when event class does not match' do
      it 'does not publish if last event is not of specified class' do
        # Create aggregate with Article2Created
        repository.store(aggregate, Article2Created, expected_version: :none)

        # Try to store Article2Submitted but aggregate has no unpublished events
        aggregate2 = repository.load(Article2Aggregate, aggregate_id)
        aggregate2.submit(actor_id: user.id)

        # If we try to store Article2Created but last event is Article2Submitted
        # it should not publish
        expect(event_store).not_to receive(:publish)
        repository.store(aggregate2, Article2Created)
      end
    end
  end

  describe 'stream_name' do
    it 'generates correct stream name for Article2Aggregate' do
      Article2Aggregate.new(aggregate_id)
      stream = repository.send(:stream_name, Article2Aggregate, aggregate_id)

      expect(stream).to eq("Article2$#{aggregate_id}")
    end

    it 'generates correct stream name for Comment2Aggregate' do
      comment_id = SecureRandom.uuid
      stream = repository.send(:stream_name, Comment2Aggregate, comment_id)

      expect(stream).to eq("Comment2$#{comment_id}")
    end
  end
end
