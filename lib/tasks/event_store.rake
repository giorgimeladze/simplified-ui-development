# frozen_string_literal: true

namespace :event_store do
  desc 'Clean up corrupted event store data'
  task cleanup: :environment do
    puts 'Cleaning up corrupted event store data...'

    # Delete all events with corrupted stream names
    ActiveRecord::Base.connection.execute(
      "DELETE FROM event_store_events_in_streams WHERE stream LIKE '%expected_version%'"
    )
    puts 'Deleted corrupted stream entries'

    # Clean up orphaned events (events not referenced in any stream)
    ActiveRecord::Base.connection.execute(<<-SQL)
      DELETE FROM event_store_events#{' '}
      WHERE event_id NOT IN (
        SELECT event_id FROM event_store_events_in_streams
      )
    SQL
    puts 'Deleted orphaned events'

    puts 'Cleanup complete!'
  end

  desc 'Show event store statistics'
  task stats: :environment do
    puts 'Event Store Statistics:'
    puts '=' * 50

    total_events = ActiveRecord::Base.connection.execute(
      'SELECT COUNT(*) FROM event_store_events'
    ).first[0]
    puts "Total events: #{total_events}"

    total_streams = ActiveRecord::Base.connection.execute(
      'SELECT COUNT(*) FROM event_store_events_in_streams'
    ).first[0]
    puts "Total stream entries: #{total_streams}"

    unique_streams = ActiveRecord::Base.connection.execute(
      'SELECT COUNT(DISTINCT stream) FROM event_store_events_in_streams'
    ).first[0]
    puts "Unique streams: #{unique_streams}"

    corrupted_streams = ActiveRecord::Base.connection.execute(
      "SELECT COUNT(*) FROM event_store_events_in_streams WHERE stream LIKE '%expected_version%'"
    ).first[0]
    puts "Corrupted streams: #{corrupted_streams}"

    puts '=' * 50
  end
end
