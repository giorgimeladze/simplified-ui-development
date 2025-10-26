class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.string :aggregate_id, null: false
      t.string :aggregate_type, null: false
      t.string :event_type, null: false
      t.json :event_data, null: false
      t.integer :version, null: false
      t.datetime :occurred_at, null: false
    end
    
    add_index :events, [:aggregate_id, :aggregate_type]
    add_index :events, [:event_type]
    add_index :events, [:occurred_at]
  end
end
