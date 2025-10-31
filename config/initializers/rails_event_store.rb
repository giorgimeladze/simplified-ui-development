require 'rails_event_store'
require 'aggregate_root'

# Single, shared client configured for ActiveRecord storage
Rails.configuration.event_store = RailsEventStore::Client.new
Rails.application.config.x.event_store = Rails.configuration.event_store

# Ensure AggregateRoot uses the same client
AggregateRoot.configure do |config|
  config.default_event_store = Rails.application.config.x.event_store
end

# Register subscribers after code load and on each reload in development
Rails.application.reloader.to_prepare do
  # Make sure classes are loaded before subscribing
  require_dependency Rails.root.join('app/subscribers/article2_projection_subscriber').to_s
  require_dependency Rails.root.join('app/projections/article2_projection').to_s
  require_dependency Rails.root.join('app/events/article2_created').to_s
  
  es = Rails.application.config.x.event_store

  # Avoid duplicate subscriptions by resetting a flag on reload
  next if Rails.application.config.x.respond_to?(:res_subscribed) && Rails.application.config.x.res_subscribed

  es.subscribe(Article2ProjectionSubscriber.new, to: [
    Article2Created,
    Article2Updated,
    Article2Submitted,
    Article2Rejected,
    Article2ApprovedPrivate,
    Article2Published,
    Article2Archived
  ])

  Rails.application.config.x.res_subscribed = true
end

