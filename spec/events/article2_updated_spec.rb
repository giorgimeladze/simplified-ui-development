# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Article2Updated do
  describe 'inheritance' do
    it 'inherits from BaseEvent' do
      expect(Article2Updated.superclass).to eq(BaseEvent)
    end
  end

  describe 'instantiation' do
    it 'can be instantiated' do
      expect { Article2Updated.new }.not_to raise_error
    end

    it 'can be instantiated with data' do
      event = Article2Updated.new(data: { article_id: '123', title: 'Updated Title' })
      expect(event.data[:article_id]).to eq('123')
      expect(event.data[:title]).to eq('Updated Title')
    end
  end

  describe 'event store compatibility' do
    it 'can be used with event store' do
      event = Article2Updated.new(data: { article_id: '123' })
      expect(event).to be_a(RubyEventStore::Event)
    end
  end
end
