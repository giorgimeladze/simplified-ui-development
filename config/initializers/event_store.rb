require 'aggregate_root'
require_dependency Rails.root.join('app/subscribers/article2_projection_subscriber').to_s
require_dependency Rails.root.join('app/subscribers/comment2_projection_subscriber').to_s
require_dependency Rails.root.join('app/projections/article2_projection').to_s
require_dependency Rails.root.join('app/projections/comment2_projection').to_s
require_dependency Rails.root.join('app/subscribers/article2_projection_subscriber').to_s
require_dependency Rails.root.join('app/subscribers/comment2_projection_subscriber').to_s
require_dependency Rails.root.join('app/events/base_event').to_s
require_dependency Rails.root.join('app/events/article2_created').to_s
require_dependency Rails.root.join('app/events/article2_updated').to_s
require_dependency Rails.root.join('app/events/article2_submitted').to_s
require_dependency Rails.root.join('app/events/article2_rejected').to_s
require_dependency Rails.root.join('app/events/article2_approved_private').to_s
require_dependency Rails.root.join('app/events/article2_published').to_s
require_dependency Rails.root.join('app/events/article2_archived').to_s
require_dependency Rails.root.join('app/events/comment2_created').to_s
require_dependency Rails.root.join('app/events/comment2_approved').to_s
require_dependency Rails.root.join('app/events/comment2_rejected').to_s
require_dependency Rails.root.join('app/events/comment2_deleted').to_s
require_dependency Rails.root.join('app/events/comment2_restored').to_s
require_dependency Rails.root.join('app/events/comment2_updated').to_s

Rails.application.config.x.event_store ||= RubyEventStore::Client.new

Rails.application.config.x.event_store.tap do |es|
  # Subscribe projection subscribers (listeners) to update read models per event
  es.subscribe(Article2ProjectionSubscriber.new, to: [
    Article2Created,
    Article2Updated,
    Article2Submitted,
    Article2Rejected,
    Article2ApprovedPrivate,
    Article2Published,
    Article2Archived
  ])

  es.subscribe(Comment2ProjectionSubscriber.new, to: [
    Comment2Created,
    Comment2Approved,
    Comment2Rejected,
    Comment2Deleted,
    Comment2Restored,
    Comment2Updated
  ])
end


