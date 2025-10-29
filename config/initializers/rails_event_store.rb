# config/initializers/rails_event_store.rb
Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::Client.new
  Rails.configuration.event_store.subscribe(Article2Subscriber.new)
  Rails.configuration.event_store.subscribe(Comment2Subscriber.new)
end
