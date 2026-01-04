# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Comment2Updated do
  describe 'inheritance' do
    it 'inherits from BaseEvent' do
      expect(Comment2Updated.superclass).to eq(BaseEvent)
    end
  end

  describe 'instantiation' do
    it 'can be instantiated' do
      expect { Comment2Updated.new }.not_to raise_error
    end

    it 'can be instantiated with data' do
      event = Comment2Updated.new(data: { comment_id: '123', text: 'Updated text' })
      expect(event.data[:comment_id]).to eq('123')
      expect(event.data[:text]).to eq('Updated text')
    end
  end

  describe 'event store compatibility' do
    it 'can be used with event store' do
      event = Comment2Updated.new(data: { comment_id: '123' })
      expect(event).to be_a(RubyEventStore::Event)
    end
  end
end
