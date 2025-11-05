require 'rails_helper'

RSpec.describe Article2Rejected do
  describe 'inheritance' do
    it 'inherits from BaseEvent' do
      expect(Article2Rejected.superclass).to eq(BaseEvent)
    end
  end

  describe 'instantiation' do
    it 'can be instantiated' do
      expect { Article2Rejected.new }.not_to raise_error
    end

    it 'can be instantiated with data' do
      event = Article2Rejected.new(data: { article_id: '123', rejection_feedback: 'Not good' })
      expect(event.data[:article_id]).to eq('123')
      expect(event.data[:rejection_feedback]).to eq('Not good')
    end
  end

  describe 'event store compatibility' do
    it 'can be used with event store' do
      event = Article2Rejected.new(data: { article_id: '123' })
      expect(event).to be_a(RubyEventStore::Event)
    end
  end
end

