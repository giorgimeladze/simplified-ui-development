# frozen_string_literal: true

class CreateEventStoreEvents < ActiveRecord::Migration[7.1]
  def change
    create_table(:event_store_events, force: false) do |t|
      t.references  :event,       null: false, type: :string, limit: 36, index: { unique: true }
      t.string      :event_type,  null: false, index: true
      t.binary      :data,        null: false
      t.datetime    :created_at,  null: false, precision: 6, index: true
    end

    create_table(:event_store_events_in_streams, force: false) do |t|
      t.string      :stream,      null: false
      t.integer     :position,    null: true, default: :null
      t.references  :event,       null: false, type: :string, limit: 36, index: true,
                                  foreign_key: { to_table: :event_store_events, primary_key: :event_id }
      t.datetime    :created_at,  null: false, precision: 6, index: true

      t.index %i[stream position], unique: true
      t.index %i[stream event_id], unique: true
    end
  end
end
