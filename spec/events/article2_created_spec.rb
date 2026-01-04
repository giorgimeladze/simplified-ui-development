# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Article2Created do
  describe 'inheritance' do
    it 'inherits from BaseEvent' do
      expect(Article2Created.superclass).to eq(BaseEvent)
    end
  end

  describe 'instantiation' do
    it 'can be instantiated' do
      expect { Article2Created.new }.not_to raise_error
    end

    it 'can be instantiated with data' do
      event = Article2Created.new(data: { article_id: '123', title: 'Test' })
      expect(event.data[:article_id]).to eq('123')
      expect(event.data[:title]).to eq('Test')
    end
  end

  describe 'event store compatibility' do
    it 'can be used with event store' do
      event = Article2Created.new(data: { article_id: '123' })
      expect(event).to be_a(RubyEventStore::Event)
      expect(event.data).to include(:article_id)
    end
  end
end
