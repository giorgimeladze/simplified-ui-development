# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Comment2Created do
  describe 'inheritance' do
    it 'inherits from BaseEvent' do
      expect(Comment2Created.superclass).to eq(BaseEvent)
    end
  end

  describe 'instantiation' do
    it 'can be instantiated' do
      expect { Comment2Created.new }.not_to raise_error
    end

    it 'can be instantiated with data' do
      event = Comment2Created.new(data: { comment_id: '123', text: 'Test comment' })
      expect(event.data[:comment_id]).to eq('123')
      expect(event.data[:text]).to eq('Test comment')
    end
  end

  describe 'event store compatibility' do
    it 'can be used with event store' do
      event = Comment2Created.new(data: { comment_id: '123' })
      expect(event).to be_a(RubyEventStore::Event)
    end
  end
end
