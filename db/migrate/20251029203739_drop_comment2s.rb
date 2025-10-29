class DropComment2s < ActiveRecord::Migration[7.1]
  def up
    drop_table :comment2s
  end

  def down
    create_table :comment2s do |t|
      t.references :article2, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :text, null: false
      t.string :status, default: 'draft', null: false
      t.text :rejection_feedback
      
      t.timestamps
    end
    
    add_index :comment2s, [:status]
  end
end
