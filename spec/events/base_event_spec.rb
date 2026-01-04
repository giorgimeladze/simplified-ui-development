# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BaseEvent do
  describe 'inheritance' do
    it 'inherits from RubyEventStore::Event' do
      expect(BaseEvent.superclass).to eq(RubyEventStore::Event)
    end
  end

  describe 'instantiation' do
    it 'can be instantiated' do
      expect { BaseEvent.new }.not_to raise_error
    end

    it 'can be instantiated with data' do
      event = BaseEvent.new(data: { test: 'value' })
      expect(event.data).to eq({ test: 'value' })
    end
  end

  describe 'event store compatibility' do
    it 'responds to event_id' do
      event = BaseEvent.new
      expect(event).to respond_to(:event_id)
    end

    it 'responds to data' do
      event = BaseEvent.new(data: {})
      expect(event).to respond_to(:data)
    end

    it 'responds to metadata' do
      event = BaseEvent.new
      expect(event).to respond_to(:metadata)
    end
  end
end
