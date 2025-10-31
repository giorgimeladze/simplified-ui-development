# frozen_string_literal: true

class CreateEventStoreEvents2 < ActiveRecord::Migration[7.1]
  def change
    add_column :event_store_events, :metadata, :binary
    add_column :event_store_events, :valid_at, :datetime, precision: 6
  end
end
