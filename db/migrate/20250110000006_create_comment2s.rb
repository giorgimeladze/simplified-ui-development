class CreateComment2s < ActiveRecord::Migration[7.1]
  def change
    create_table :comment2s do |t|
      t.integer :article2_id, null: false
      t.integer :user_id, null: false
      t.text :text, null: false
      t.string :status, default: 'pending', null: false
      t.text :rejection_feedback
      
      t.timestamps
    end
    
    add_index :comment2s, [:article2_id]
    add_index :comment2s, [:user_id]
    add_index :comment2s, [:status]
    add_foreign_key :comment2s, :article2s
    add_foreign_key :comment2s, :users
  end
end
