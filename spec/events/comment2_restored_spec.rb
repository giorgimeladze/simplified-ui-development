require 'rails_helper'

RSpec.describe Comment2Restored do
  describe 'inheritance' do
    it 'inherits from BaseEvent' do
      expect(Comment2Restored.superclass).to eq(BaseEvent)
    end
  end

  describe 'instantiation' do
    it 'can be instantiated' do
      expect { Comment2Restored.new }.not_to raise_error
    end

    it 'can be instantiated with data' do
      event = Comment2Restored.new(data: { comment_id: '123' })
      expect(event.data[:comment_id]).to eq('123')
    end
  end

  describe 'event store compatibility' do
    it 'can be used with event store' do
      event = Comment2Restored.new(data: { comment_id: '123' })
      expect(event).to be_a(RubyEventStore::Event)
    end
  end
end

