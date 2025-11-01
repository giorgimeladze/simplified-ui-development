require 'rails_event_store'
require 'aggregate_root'

# Single, shared client configured for ActiveRecord storage
# RailsEventStore::Client.new automatically detects ActiveRecord
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
  require_dependency Rails.root.join('app/subscribers/comment2_projection_subscriber').to_s
  require_dependency Rails.root.join('app/projections/article2_projection').to_s
  require_dependency Rails.root.join('app/projections/comment2_projection').to_s
  require_dependency Rails.root.join('app/events/article2_created').to_s
  require_dependency Rails.root.join('app/events/article2_updated').to_s
  require_dependency Rails.root.join('app/events/article2_submitted').to_s
  require_dependency Rails.root.join('app/events/article2_rejected').to_s
  require_dependency Rails.root.join('app/events/article2_approved_private').to_s
  require_dependency Rails.root.join('app/events/article2_published').to_s
  require_dependency Rails.root.join('app/events/article2_archived').to_s
  require_dependency Rails.root.join('app/events/comment2_created').to_s
  require_dependency Rails.root.join('app/events/comment2_updated').to_s
  require_dependency Rails.root.join('app/events/comment2_approved').to_s
  require_dependency Rails.root.join('app/events/comment2_rejected').to_s
  require_dependency Rails.root.join('app/events/comment2_deleted').to_s
  require_dependency Rails.root.join('app/events/comment2_restored').to_s
  
  es = Rails.application.config.x.event_store

  # # Avoid duplicate subscriptions by resetting a flag on reload
  # next if Rails.application.config.x.respond_to?(:res_subscribed) && Rails.application.config.x.res_subscribed

  puts("[RES] Registering subscribers...")
  es.subscribe(Article2ProjectionSubscriber.new, to: [
    Article2Created,
    Article2Updated,
    Article2Submitted,
    Article2Rejected,
    Article2ApprovedPrivate,
    Article2Published,
    Article2Archived
  ])
  puts("[RES] Article2ProjectionSubscriber registered")

  es.subscribe(Comment2ProjectionSubscriber.new, to: [
    Comment2Created,
    Comment2Updated,
    Comment2Approved,
    Comment2Rejected,
    Comment2Deleted,
    Comment2Restored
  ])
  puts("[RES] Comment2ProjectionSubscriber registered")

  Rails.application.config.x.res_subscribed = true
end
