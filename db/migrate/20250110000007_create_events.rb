class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.string :aggregate_id, null: false
      t.string :aggregate_type, null: false
      t.string :event_type, null: false
      t.json :event_data, null: false
      t.integer :version, null: false
      t.datetime :occurred_at, null: false
      t.string :correlation_id
      t.string :causation_id
      
      t.timestamps
    end
    
    add_index :events, [:aggregate_id, :aggregate_type]
    add_index :events, [:event_type]
    add_index :events, [:occurred_at]
    add_index :events, [:correlation_id]
    add_index :events, [:causation_id]
  end
end
