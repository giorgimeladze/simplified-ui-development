# frozen_string_literal: true

class CreateStateTransitions < ActiveRecord::Migration[7.1]
  def change
    create_table :state_transitions do |t|
      t.references :transitionable, polymorphic: true, null: false
      t.string :from_state, null: false
      t.string :to_state, null: false
      t.string :event, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
